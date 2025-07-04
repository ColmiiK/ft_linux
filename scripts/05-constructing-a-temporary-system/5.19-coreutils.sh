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
tarball="coreutils-8.30"

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

./configure --prefix=/tools --enable-install-program=hostname

make
make RUN_EXPENSIVE_TESTS=yes check
make install

#########################
# Generic cleanup steps #
#########################
cd $LFS/sources
rm -rf $tarball
