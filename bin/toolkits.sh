#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/config/targets.txt"
APPS_FILE="$ROOT/config/apps.txt"
SRC_DIR="$ROOT/src"
PKG_DIR="$ROOT/pkg"

usage() {
  echo "Usage: toolkits.sh <command> <args...>" >&2
  echo "       toolkits.sh package <os-name>  - Package the application for the given OS" >&2
  echo "       toolkits.sh add <os-name> <app-name> <description> - Add a new app for given OS" >&2
  exit 1
}

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# Prints: Name|src_ext|pkg_ext|description
lookup_target() {
  local os="$1"
  local line name src_ext pkg_ext desc

  if [[ ! -f "$CONFIG" ]]; then
    echo "Config not found: $CONFIG" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    IFS=',' read -r name src_ext pkg_ext desc <<< "$line"
    name="$(trim "$name")"
    src_ext="$(trim "$src_ext")"
    pkg_ext="$(trim "$pkg_ext")"
    desc="$(trim "${desc:-}")"

    if [[ "$(lower "$name")" == "$(lower "$os")" ]]; then
      printf '%s|%s|%s|%s\n' "$name" "$src_ext" "$pkg_ext" "$desc"
      return 0
    fi
  done < "$CONFIG"

  echo "Unknown OS: $os (not found in $CONFIG)" >&2
  return 1
}

# Collect source files under src/ with the target source extension.
# Prints relative paths from src/ (e.g. bin/tks.lnx).
list_source_files() {
  local src_ext="$1"
  local file rel

  [[ -d "$SRC_DIR" ]] || return 0

  while IFS= read -r -d '' file; do
    rel="${file#"$SRC_DIR"/}"
    printf '%s\0' "$rel"
  done < <(find "$SRC_DIR" -type f -name "*.${src_ext}" -print0 | sort -z)
}

rel_to_pkg() {
  local rel="$1"
  local src_ext="$2"
  local pkg_ext="$3"
  printf '%s.%s\n' "${rel%.${src_ext}}" "$pkg_ext"
}

# Write pkg/config/apps.txt with only rows whose OS name matches.
write_pkg_apps() {
  local os="$1"
  local dest="$PKG_DIR/config/apps.txt"
  local line app_name app_os count=0

  if [[ ! -f "$APPS_FILE" ]]; then
    echo "Apps file not found: $APPS_FILE" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dest")"
  : > "$dest"

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    IFS=',' read -r app_name app_os _ <<< "$line"
    app_os="$(trim "$app_os")"

    if [[ "$(lower "$app_os")" == "$(lower "$os")" ]]; then
      printf '%s\n' "$line" >> "$dest"
      count=$((count + 1))
    fi
  done < "$APPS_FILE"

  echo "$APPS_FILE -> $dest ($count app(s))"
}

cmd_package() {
  local os="$1"
  local target name src_ext pkg_ext
  local rel dest count=0

  target="$(lookup_target "$os")"
  IFS='|' read -r name src_ext pkg_ext _ <<< "$target"

  rm -rf "$PKG_DIR"
  mkdir -p "$PKG_DIR"

  while IFS= read -r -d '' rel; do
    dest="$PKG_DIR/$(rel_to_pkg "$rel" "$src_ext" "$pkg_ext")"
    mkdir -p "$(dirname "$dest")"
    cp "$SRC_DIR/$rel" "$dest"
    echo "$SRC_DIR/$rel -> $dest"
    count=$((count + 1))
  done < <(list_source_files "$src_ext")

  if [[ "$count" -eq 0 ]]; then
    echo "No *.$src_ext files found under $SRC_DIR" >&2
    exit 1
  fi

  write_pkg_apps "$name"

  local hook="$ROOT/bin/${name}_package.sh"
  if [[ ! -x "$hook" && ! -f "$hook" ]]; then
    echo "Package hook not found: $hook" >&2
    exit 1
  fi
  bash "$hook"
}

app_exists() {
  local app="$1"
  local os="$2"
  local line app_name app_os

  [[ -f "$APPS_FILE" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    IFS=',' read -r app_name app_os _ <<< "$line"
    app_name="$(trim "$app_name")"
    app_os="$(trim "$app_os")"

    if [[ "$(lower "$app_name")" == "$(lower "$app")" && "$(lower "$app_os")" == "$(lower "$os")" ]]; then
      return 0
    fi
  done < "$APPS_FILE"

  return 1
}

cmd_add() {
  local os="$1"
  local app="$2"
  local desc="$3"
  local target name src_ext
  local action dir file

  if [[ -z "$app" || -z "$desc" ]]; then
    usage
  fi

  target="$(lookup_target "$os")"
  IFS='|' read -r name src_ext _ _ <<< "$target"

  if app_exists "$app" "$name"; then
    echo "App already exists: $app ($name)" >&2
    exit 1
  fi

  mkdir -p "$ROOT/config"
  if [[ -s "$APPS_FILE" && -n "$(tail -c 1 "$APPS_FILE" 2>/dev/null || true)" ]]; then
    printf '\n' >> "$APPS_FILE"
  fi
  printf '%s, %s, %s\n' "$app" "$name" "$desc" >> "$APPS_FILE"
  echo "Added $app to $APPS_FILE"

  for action in install uninstall update; do
    dir="$SRC_DIR/bin/$action"
    file="$dir/${app}.${src_ext}"
    mkdir -p "$dir"
    if [[ -e "$file" ]]; then
      echo "File already exists: $file" >&2
      exit 1
    fi
    printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' > "$file"
    chmod +x "$file"
    echo "Created $file"
  done
}

if [[ $# -lt 2 ]]; then
  usage
fi

COMMAND="$1"
OS_NAME="$2"

case "$COMMAND" in
  package)
    [[ $# -eq 2 ]] || usage
    cmd_package "$OS_NAME"
    ;;
  add)
    [[ $# -eq 4 ]] || usage
    cmd_add "$OS_NAME" "$3" "$4"
    ;;
  *)
    echo "Unknown command: $COMMAND" >&2
    usage
    ;;
esac
