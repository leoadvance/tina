#!/bin/sh

echo "OTA" > /dev/ttys0
pkill BranQt4

# 回根目录
cd /

# 执行升级命令
aw_upgrade_process.sh -f -n

# 删除overlay
#cd /overlay
#rm -rf *

# 运行need todo
cd /bin/qtapp
chmod 777 OTA_Todo.sh
./OTA_Todo.sh

