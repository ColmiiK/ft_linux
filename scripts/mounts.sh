#!/bin/bash

# Change /dev/sdbX to the correct drive on your machine (lsblk)
mount -v -t ext4 /dev/sdb3 $LFS
mount -v -t ext4 /dev/sdb1 $LFS/boot
swapon -v /dev/sdb2
mount -v --bind /dev $LFS/dev
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
