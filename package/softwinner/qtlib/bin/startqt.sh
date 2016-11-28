#!/bin/sh

mkdir -p /tmp/class/esp_boot

export PATH=/usr/bin:/usr/sbin:/bin:/sbin
export LD_LIBRARY_PATH=/lib/qtlib
export QT_QWS_FONTDIR=/lib/qtlib/fonts
export QWS_DISPLAY=Transformed:Rot270
export TSLIB_CONFFILE=/etc/ts.conf
export TSLIB_PLUGINDIR=/lib/qtlib/ts
export TSLIB_CALIBFILE=/etc/pointercal
export TSLIB_CONSOLEDEVICE=none
export TSLIB_FBDEVICE=/dev/fb0
export TSLIB_TSDEVICE=/dev/input/event4
export QWS_MOUSE_PROTO=tslib:/dev/input/event4


cd /bin/qtapp
./baklight 128

logread -f >> kernel.log &

export QWS_DISPLAY=Transformed:Rot270
./BranQt4 -qws -font &
