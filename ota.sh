if [ $1 == "SystemUpdate" ]
	then
	echo "do System Update"
	# 升级命令
	aw_upgrade_process.sh -f -l /mnt/UDISK

	# 执行绝对路径升级标志位 
	/sbin/write_misc -s ota

	elif [ $1 == "BranUpdate" ]
  	then
  	echo "Bran Update"
	else
  	echo "Please make sure the positon variable is SystemUpdate or BranUpdate."
fi


