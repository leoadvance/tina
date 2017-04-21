#!/bin/sh

# 删除此时的device.token
echo "remove /bin/qtapp/device.token"
rm /bin/qtapp/device.token

# 终止此时的miio程序
echo "kill miio_client"
kill -9 `ps -ef|grep "miio_client" |grep -v "grep"|awk '{print $2}'`

# 重新运行此时的miio程序
echo "start miio_client"
/bin/qtapp/miio/miio_client -D
/bin/qtapp/miio/miio_client_helper_nomqtt.sh &
