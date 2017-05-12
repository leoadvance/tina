if [ $1 == "SystemUpdate" ]
	then
	echo "do System Update"

	echo "need do ota"
	
	# 删除原有目录etc 并备份
	rm -rf /mnt/UDISK/etc
	cp -f /overlay/usr/bin/qtapp/etc /mnt/UDISK/etc
	
	# 删除overlay 并还原etc
	rm -rf  /overlay/usr/bin/qtapp
	cp -f   /mnt/UDISK/etc /overlay/usr/bin/qtapp/etc
	
	# 删除 UDISK目录
	#rm -rf /mnt/UDISK/
	echo "Delete overlay"

	# 升级命令
	aw_upgrade_process.sh -f -l /mnt/UDISK

	# 执行绝对路径升级标志位 
	/sbin/write_misc -s ota

	reboot

	elif [ $1 == "BranUpdate" ]
  	then
  	echo "Bran Update"
	else
  	echo "Please make sure the positon variable is SystemUpdate or BranUpdate."
fi


