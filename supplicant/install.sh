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

	ln -sf /etc/init.d/supplicant /etc/rc.d/S95supplicant
	ln -sf /etc/init.d/supplicant /etc/rc.d/K95supplicant

	echo "Install success!"
	
	/etc/init.d/supplicant reload
	
	return 0
}

install
