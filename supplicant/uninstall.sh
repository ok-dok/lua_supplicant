#!/bin/sh

HOME='/usr/share/supplicant'
/etc/init.d/supplicant stop &> /dev/null
##删除定时任务、开机启动
sed -i '/supplicant/d' /etc/crontabs/root
rm -f /etc/rc.d/S95supplicant
rm -f /etc/rc.d/K95supplicant
rm -f /etc/init.d/supplicant
if [ -d $HOME ]; then  
	rm -rf $HOME  
fi 
echo "Uninstall success!"
