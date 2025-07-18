#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

grub-install /dev/sdb

cat >/boot/grub/grub.cfg <<"EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,1)

menuentry "GNU/Linux, Linux 4.20.12-alvega-g" {
        linux   /vmlinuz-4.20.12-alvega-g root=/dev/sda4 ro
}
EOF
