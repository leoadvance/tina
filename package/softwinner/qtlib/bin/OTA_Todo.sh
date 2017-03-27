#!/bin/sh

echo "OTA Todo" 

# 删除overlay脚本
rm -rf /overlay/bin/qtapp/IMG_Version
rm -rf /overlay/bin/qtapp/*.sh


cd /overlay

reboot
