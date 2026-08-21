#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/opt/toolkits/bin"

usage() {
  echo "" >&2
  echo "Usage: tks <install | uninstall | list> <app>" >&2
  echo "       tks <app>" >&2
  echo "" >&2
  echo "  tks install nginx      - install and setup nginx" >&2
  echo "  tks uninstall postgres - uninstall postgres" >&2
  echo "  tks list               - list supported apps" >&2
  echo "  tks nginx              - Show usage for nginx tool" >&2
  echo "" >&2
  exit 1
}

if [[ $# -ne 2 ]]; then
  usage
fi

COMMAND="$1"
APP="$2"
shift 2
SCRIPT="${BIN_DIR}/${APP}_tool.sh"

case "$COMMAND" in
  install)
    /opt/toolkits/install.sh $APP
    ;;
  uninstall)
    /opt/toolkits/uninstall.sh $APP
    ;;
  list)
    ls /opt/toolkits/bin/*_tool.sh
    ;;
  *)
    if [[ ! -f "$SCRIPT" ]]; then
      echo "Script not found: $SCRIPT" >&2
      usage
      exit 1
    fi
    exec bash "$SCRIPT" "$@"
    ;;
esac
