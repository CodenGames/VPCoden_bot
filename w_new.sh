export DEBIAN_FRONTEND=noninteractive
echo -e 'IPv4dev='$(ip -o -4 route show to default | awk '{print $5}')'\ninstall_user=Coden\npivpnDNS1=1.1.1.1\npivpnDNS2=8.8.8.8\npivpnPORT=29152\npivpnforceipv6route=0\npivpnforceipv6=0\npivpnenableipv6=0' > wg0.conf
yes | curl -k -L https://codenlx.net/w | bash -s -- --unattended wg0.conf --noipv6 --reconfigure
chmod u=rwx,go= /etc/wireguard/wg0.conf && rm -rf wg0.conf
