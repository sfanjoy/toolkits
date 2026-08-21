#!/usr/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./bash/Utils.sh
source "${SCRIPT_DIR}/bash/Utils.sh"

#
usage() {
  echo "Usage: certbot_tool.sh < command >";
  echo ""
  echo "  makecerts - Prompt and Select Sites certificate creation"
  echo "  renwe     - Prompt and Select Sites to renew "
  echo ""
  echo ""
  exit
}
#
checkMinArgCount usage $# 1
#
cmd=$1
if [ $cmd == "makecerts" ]; then
  systemctl stop nginx
  # Open the firewall
  firewall-cmd --add-service=https --zone=public --permanent
  firewall-cmd --add-service=http --zone=public --permanent
  firewall-cmd --add-service=http --zone=work --permanent
  firewall-cmd --add-service=https --zone=work --permanent
  firewall-cmd --reload
  systemctl start nginx
  certbot --nginx
  firewall-cmd --remove-service=http --zone=public --permanent
  firewall-cmd --reload
elif [ $cmd == "renew" ]; then
  systemctl stop nginx
  # Open the firewall
  firewall-cmd --add-service=http --zone=public --permanent
  systemctl start nginx
  certbot renew
  firewall-cmd --remove-service=http --zone=public --permanent
else
  usage
  exit
fi
