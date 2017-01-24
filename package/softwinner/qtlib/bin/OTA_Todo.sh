#!/bin/sh

echo "OTA Todo" 


rm -rf /overlay/bin/qtapp/IMG_Version
rm -rf /overlay/bin/qtapp/*.sh

# 删除voerlay
cd /overlay

reboot
