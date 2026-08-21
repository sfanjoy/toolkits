#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/opt/toolkits/bin"

usage() {
  echo "" >&2
  echo "Usage: uninstall.sh <app>" >&2
  echo "" >&2
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
fi

APP="$1"
shift
SCRIPT="${BIN_DIR}/${APP}_tool.sh"

case "$APP" in
  nginx)
    systemctl stop nginx
    systemctl disable nginx
    rm -f /etc/nginx/nginx-selfsigned.crt
    rm -rf /etc/nginx/sites-available
    rm -rf /etc/nginx/sites-enabled
    setsebool -P httpd_can_network_connect 0
    dnf -y remove nginx
  exit
    ;;
  certbot)
    # https://snapcraft.io/docs/installing-snap-on-centos
    systemctl stop snapd
    systemctl disable --now snapd.socket
    snap uninstall --classic certbot
    dnf -y remove snapd
    rm -f /snap/bin/certbot
    rm -f /usr/bin/certbot
    ;;
  firewall)
    dnf -y remove firewalld
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
