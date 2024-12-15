#!/bin/bash

if command -v pivpn &> /dev/null
then
    sed -i 's/443/29152/g' /etc/wireguard/wg0.conf && systemctl reboot
else
    echo -e 'IPv4dev='$(ip -o -4 route show to default | awk '{print $5}')'\ninstall_user=NO_ROOT_USER\npivpnDNS1=1.1.1.1\npivpnDNS2=8.8.8.8\npivpnPORT=29152\npivpnforceipv6route=0\npivpnforceipv6=0\npivpnenableipv6=0' > wg0.conf
    curl -L https://install.pivpn.io > install.sh
    chmod +x install.sh
    ./install.sh --unattended wg0.conf
    sudo chmod u=rwx,go= /etc/wireguard/wg0.conf
fi
