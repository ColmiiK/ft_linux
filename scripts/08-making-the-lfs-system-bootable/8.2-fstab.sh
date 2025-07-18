#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

echo "It's essential this file is configured properly, otherwise the boot will not succeed"
echo "Run 'lslkb' to check your partitions"
echo "Consider that if you remove the other VDI, the LFS VDI will become /dev/sda"
echo "You can also run 'blkid' to assign UUIDs instead of aliases"

cat >/etc/fstab <<"EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda1      /boot        ext2     defaults            1     1
/dev/sda4      /            ext4     defaults            1     1
/dev/sda3      swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF
