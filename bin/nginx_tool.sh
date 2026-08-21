#!/usr/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./bash/Utils.sh
source "${SCRIPT_DIR}/bash/Utils.sh"

#
usage() {
  echo "Usage: nginx_tool.sh < command > < options >";
  echo ""
  echo "  enable <website>             - symlink sites-available to sites-enabled"
  echo "  firewall < test|demo|prod >  - open firewall sources/ports"
  echo "  status                       - show run info and site configuration"
  echo ""
  echo ""
  exit
}
#
checkMinArgCount usage $# 1
#
cmd=$1
if [ "$cmd" == "status" ]; then
  systemctl status nginx --no-pager
  ls /etc/nginx/sites-*
elif [ "$cmd" == "enable" ]; then
  SITE=$2
  rm -f /etc/nginx/sites-enabled/$SITE
  ln -s /etc/nginx/sites-available/$SITE /etc/nginx/sites-enabled/
  systemctl restart nginx
  systemctl status nginx --no-pager
elif [ "$cmd" == "disable" ]; then
  checkMinArgCount usage $# 2
  SITE=$2
  rm -f /etc/nginx/sites-enabled/$SITE
elif [ $1 == "firewall" ]; then
  echo "Removing current firewall settings..."
  systemctl stop nginx
  firewall-cmd --remove-service=https --zone=public --permanent
  firewall-cmd --remove-service=http --zone=public --permanent
  firewall-cmd --remove-service=https --zone=work --permanent
  firewall-cmd --remove-service=http --zone=work --permanent
  echo "Configuring firewall"
  firewall-cmd --add-service=https --zone=public --permanent
  firewall-cmd --add-service=http --zone=work --permanent
  firewall-cmd --add-service=https --zone=work --permanent
  firewall-cmd --reload
  systemctl start nginx
else
  echo "Unknown option <$1>"
  exit
fi
