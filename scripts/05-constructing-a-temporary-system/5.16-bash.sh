#!/bin/bash

# Ensure user is lfs
if ! whoami | grep -q "lfs"; then
  echo "ERROR: Please become lfs: 'su - lfs'"
  exit 1
fi
# Ensure $LFS is set
if ! echo $LFS | grep -q "/mnt/lfs"; then
  echo 'ERROR: Please set the "$LFS" variable before continuing'
  exit 1
fi

################
# Tarball name #
################
tarball="bash-5.0"

########################
# Generic build steps  #
########################
cd $LFS/sources
tar -xvf $tarball.tar.xz
if [ ! -d $LFS/sources/$tarball ]; then
  echo "ERROR: Unable to extract tarball named $tarball.tar.xz, trying another extension..."
  tar -xvf $tarball.tar.gz
  if [ ! -d $LFS/sources/$tarball ]; then
    echo "ERROR: Unable to extract tarball named $tarball.tar.gz, stopping..."
    exit 1
  fi
fi
cd $tarball

########################
# Specific build steps #
#########################
./configure --prefix=/tools --without-bash-malloc

make
# make tests
make install
ln -sv bash /tools/bin/sh

#########################
# Generic cleanup steps #
#########################
cd $LFS/sources
rm -rf $tarball
