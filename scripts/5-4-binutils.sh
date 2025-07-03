#!/bin/bash

# Ensure user is lfs
if ! whoami | grep -q "lfs"; then
  echo "Please become lfs"
  su - lfs
fi

if ! echo $LFS | grep -q "/mnt/lfs"; then
  echo 'Please set the $LFS variable'
  exit 1
fi

cd $LFS/sources
tar -xvf
