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
tarball="findutils-4.6.0"

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

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >>gl/lib/stdio-impl.h

./configure --prefix=/tools
make
# make check
make install

#########################
# Generic cleanup steps #
#########################
cd $LFS/sources
rm -rf $tarball
