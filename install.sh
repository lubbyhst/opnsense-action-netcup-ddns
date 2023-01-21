#!/usr/local/bin/bash

set -e

echo "copy action conf"
cp ./actions_netcup_ddns.conf /usr/local/opnsense/service/conf/actions.d/actions_netcup_ddns.conf
echo "reload action config"
service configd restart
echo "copy update script to bin folder"
cp ./update_netcup_ddns.sh /usr/local/bin/update_netcup_ddns.sh
echo "make script executable"
chmod +x /usr/local/bin/update_netcup_ddns.sh
echo "install done"