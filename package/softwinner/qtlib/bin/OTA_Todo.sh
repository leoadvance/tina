#!/bin/sh

echo "OTA Todo" > /dev/ttys0

# 删除voerlay
cd /overlay

reboot
