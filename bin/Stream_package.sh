#!/usr/bin/env bash
set -euo pipefail

# Stream-specific packaging hook. Invoked by toolkits.sh after files are staged in pkg/.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg="$root/pkg"

if [[ ! -d "$pkg" ]]; then
  echo "Stream_package.sh: pkg/ directory not found at $pkg" >&2
  exit 1
fi

rpm puild -bb "$root/config/rpm/Stream.spec"
