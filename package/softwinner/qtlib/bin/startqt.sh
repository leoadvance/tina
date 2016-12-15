#!/bin/sh


ETC_PROFILE_ADDR=/etc/profile
TP_EVENT_ADDR=/proc/bus/input/devices

# 获取tp event号
TP_EVENT=`cat $TP_EVENT_ADDR | grep -A 5 'ft5x_ts' | grep -Eo 'event[0-9]+'` 
echo ${TP_EVENT} 

# 删除profile原配置
sed -i '/^export TSLIB_TSDEVICE=/d' $ETC_PROFILE_ADDR
sed -i '/^export QWS_MOUSE_PROTO=/d' $ETC_PROFILE_ADDR


# 插入新内容
sed -i '/^export TSLIB_FBDEVICE=/a\export TSLIB_TSDEVICE=/dev/input/'$TP_EVENT'' $ETC_PROFILE_ADDR
sed -i '/^export TSLIB_FBDEVICE=/a\export QWS_MOUSE_PROTO=tslib:/dev/input/'$TP_EVENT'' $ETC_PROFILE_ADDR

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
export QWS_MOUSE_PROTO=tslib:/dev/input/${TP_EVENT} 
export TSLIB_TSDEVICE=/dev/input/${TP_EVENT} 


cd /bin/qtapp


logread -f >> kernel.log &

export QWS_DISPLAY=Transformed:Rot270
/bin/qtapp/BranQt4 -qws -font &
