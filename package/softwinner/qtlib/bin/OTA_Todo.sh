#!/bin/sh

echo "OTA Todo" 

# 删除overlay脚本
rm -rf /overlay/usr/bin/qtapp/IMG_Version
rm -rf /overlay/usr/bin/qtapp/SysSVN
rm -rf /overlay/usr/bin/qtapp/BranQt4
rm -rf /overlay/usr/bin/qtapp/Hodor
rm -rf /overlay/usr/bin/qtapp/*.sh
rm -rf /overlay/usr/bin/qtapp/miio
rm -rf /overlay/etc/os-release
# 删除原有库
rm -rf /overlay/usr/lib/qtlib

cd /overlay

reboot
