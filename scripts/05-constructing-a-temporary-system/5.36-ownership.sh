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

chown -R root:root $LFS/tools
