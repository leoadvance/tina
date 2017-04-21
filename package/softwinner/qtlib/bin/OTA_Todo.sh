#!/bin/sh

echo "OTA Todo" 

# 删除overlay脚本
rm -rf /overlay/bin/qtapp/IMG_Version
rm -rf /overlay/bin/qtapp/SysSVN
rm -rf /overlay/bin/qtapp/BranQt4
rm -rf /overlay/bin/qtapp/Hodor
rm -rf /overlay/bin/qtapp/*.sh
rm -rf /overlay/bin/qtapp/miio/*.sh

# 删除原有库
rm -rf /overlay/lib/qtlib

cd /overlay

reboot
