#!/bin/sh
home="/usr/share/supplicant"
config_file="${home}/bin/conf.lua"
authc_file="${home}/bin/authc.lua"

install() {
	echo "Installing..."
	cp -r ../supplicant /usr/share/
	echo "Configuring..."
	sh ${home}/bin/configure.sh
	if [ -e ${config_file} ] && [ -e ${authc_file} ]; then
		echo "Configure success!"
	else
		echo "Configure failed! Install canceled."
		rm -r /usr/share/supplicant
		return
	fi
	mv ${home}/install.sh ${home}/install.sh.lock
	cp ${home}/init.d/supplicant /etc/init.d/
	chmod +x /etc/init.d/supplicant
	ln -sf /etc/init.d/supplicant /etc/rc.d/S95supplicant
	ln -sf /etc/init.d/supplicant /etc/rc.d/K95supplicant
	echo "0 7 * * * /etc/init.d/supplicant restart" >> /etc/crontabs/root
	
	echo "Install success!"
}

install
