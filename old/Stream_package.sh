#!/usr/bin/env bash
set -euo pipefail

# Stream-specific packaging hook. Invoked by toolkits.sh after files are staged in pkg/.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pkg="$root/pkg"

if [[ ! -d "$pkg" ]]; then
  echo "Stream_package.sh: pkg/ directory not found at $pkg" >&2
  exit 1
fi

# Copy Basic Configurations
cp $root/config/nginx.conf pkg/config

# Package the Base
rpmbuild -bb $root/config/Stream.spec
