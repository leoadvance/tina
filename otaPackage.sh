#!/bin/sh

rm -r ota/*.img
rm -r ota/*.sh
rm -r ota/*.tar.gz
rm -r ota/md5


cp -f bin/sun5i/ota/ramdisk_sys.tar.gz ota/ramdisk_sys.tar.gz
cp -f bin/sun5i/ota/target_sys.tar.gz ota/target_sys.tar.gz
cp -f bin/sun5i/ota/usr_sys.tar.gz ota/usr_sys.tar.gz
cp -f ota.sh ota/ota.sh

cd ota

md5sum ramdisk_sys.tar.gz >> md5
md5sum target_sys.tar.gz >> md5
md5sum usr_sys.tar.gz >> md5
md5sum ota.sh >> md5

tar -zcvf ota.tar.gz *

