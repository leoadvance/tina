#!/bin/sh

pkill BranQt4

# 回根目录
cd /

# 执行升级命令
aw_upgrade_process.sh -f -n

# 删除overlay
cd /overlay
rm -rf *

reboot
