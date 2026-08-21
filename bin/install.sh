#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/opt/toolkits/bin"

usage() {
  echo "" >&2
  echo "Usage: install.sh <app>" >&2
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
    dnf -y install nginx
    setsebool -P httpd_can_network_connect 1
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/nginx-selfsigned.key -out /etc/nginx/nginx-selfsigned.crt
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/nginx/sites-available
    TDAY=`date "+%Y%m%d-%s"`
    mv -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf.$TDAY
    install -m 0644 /opt/toolkits/config/nginx.conf /etc/nginx/nginx.conf
    systemctl enable --now nginx
    systemctl start nginx
    systemctl status nginx --no-pager
    /opt/toolkits/install.sh $APP
    ;;
  certbot)
    # https://snapcraft.io/docs/installing-snap-on-centos
    dnf -y install epel-release
    dnf -y install snapd
    systemctl enable --now snapd.socket
    ln -s /var/lib/snapd/snap /snap
    systemctl start snapd
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    /opt/toolkits/uninstall.sh $APP
    ;;
  firewall)
    dnf -y install firewalld
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
