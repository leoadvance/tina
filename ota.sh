#!/bin/sh

rm -r ota
mkdir ota

cp -f bin/sun5i/ota/ramdisk_sys/boot_initramfs.img ota/boot_initramfs.img
cp -f bin/sun5i/ota/target_sys/boot.img ota/boot.img
cp -f bin/sun5i/ota/target_sys/rootfs.img ota/rootfs.img
cp -f bin/sun5i/ota/usr_sys/usr.img ota/usr.img

cd ota

tar -zcvf ota.tar.gz *

