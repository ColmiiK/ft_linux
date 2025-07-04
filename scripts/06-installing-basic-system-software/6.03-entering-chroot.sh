#!/bin/bash

# Ensure user is lfs
if ! whoami | grep -q "root"; then
  echo "ERROR: Please become root: 'su'"
  exit 1
fi
# Ensure $LFS is set
if ! echo $LFS | grep -q "/mnt/lfs"; then
  echo 'ERROR: Please set the "$LFS" variable before continuing'
  exit 1
fi

sudo chroot "$LFS" /tools/bin/env -i \
  HOME=/root \
  TERM="$TERM" \
  PS1='(lfs chroot) \u:\w\$ ' \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /tools/bin/bash --login +h
