#!/bin/sh
home="/usr/share/supplicant"
config_file="${home}/bin/conf.lua"
authc_file="${home}/bin/authc.lua"

install() {
	echo "Installing..."
	if [ ! -e ${home} ]; then
		mkdir ${home}
	fi
	cp -r ./ ${home}

	rm -f ${home}/install.sh
	cp ${home}/init.d/supplicant /etc/init.d/
	chmod +x /etc/init.d/supplicant

	/etc/init.d/supplicant reload
	
	echo "Install success!"
	return 0
}

install
