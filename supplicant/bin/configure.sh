#!/bin/sh

home="/usr/share/supplicant/bin"
config_file="${home}/conf.lua"
authc_file="${home}/authc.lua"
supplicant="${home}/supplicant.lua"
dhcp='0'
version='3.8.2'

mac_addr=$(uci get network.wan.macaddr)
ifname=$(uci get network.wan.ifname)
if [ "${ifname}" == "" ]; then
	ifname=$(uci get network.wan.def_ifname)
fi
eval $(ifconfig $ifname | awk '/inet addr/ {printf("ip=%s", $2)}' | awk -F: '{printf("ip=%s",$2)}')

username=""
while [ "$username" == "" ] 
do
	echo -n "Username: "
	read username
done
password=""
while [ "$password" == "" ] 
do
	echo -n "Password: "
	read password
done

echo "#!/usr/bin/lua" > $config_file
echo "dhcp='$dhcp'" >> $config_file
echo "version='$version'" >> $config_file
echo "mac_addr='$mac_addr'" >> $config_file
echo "ip='$ip'" >> $config_file
echo "#!/usr/bin/lua" > $authc_file
echo "username='$username'" >> $authc_file
echo "password='$password'" >> $authc_file

lua ${supplicant} -t
