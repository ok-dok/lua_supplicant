#!/bin/sh
home="/usr/share/supplicant"
config_file="${home}/bin/conf.lua"
authc_file="${home}/bin/authc.lua"

install() {
	echo "Installing..."
	if [ ! -e ${home} ]; then
		mkdir ${home}
	fi
	cp ./* ${home}
	echo "Configuring..."
	sh ${home}/bin/configure.sh
	if [ ! -e ${authc_file} ]; then
		echo "Username or password error！Configure failed, Install canceled."
		rm -r ${home}
		return -1
	fi
	echo "Configure success!"
	
	mv ${home}/install.sh ${home}/install.sh.lock
	cp ${home}/init.d/supplicant /etc/init.d/
	chmod +x /etc/init.d/supplicant
	ln -sf /etc/init.d/supplicant /etc/rc.d/S95supplicant
	ln -sf /etc/init.d/supplicant /etc/rc.d/K95supplicant
	echo "0 7 * * * /etc/init.d/supplicant restart" >> /etc/crontabs/root
	
	echo "Install success!"
	return 0
}

install
