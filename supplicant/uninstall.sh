#!/bin/sh

HOME='/usr/share/supplicant'
/etc/init.d/supplicant stop
##删除定时任务
sed -i '/supplicant/d' /etc/crontabs/root
rm /etc/rc.d/S95supplicant
rm /etc/rc.d/K95supplicant
rm /etc/init.d/supplicant
if [ -d $HOME ]; then  
	rm -r $HOME  
fi 
echo "Uninstall success!"
