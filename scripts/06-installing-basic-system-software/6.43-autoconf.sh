#!/bin/bash

# URL https://www.linuxfromscratch.org/museum/lfs-museum/8.4/LFS-BOOK-8.4-HTML/chapter06/autoconf.html

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='autoconf-2.69'

########################
# Generic build steps  #
########################
cd /sources
echo "Extracting $tarball..."
tar -xvf $tarball.tar.xz >/dev/null 2>&1
tar -xvf $tarball.tar.gz >/dev/null 2>&1
tar -xvf $tarball.tar.bz2 >/dev/null 2>&1
if [ ! -d /sources/$tarball ]; then
  echo "ERROR: Unable to extract tarball named $tarball"
  exit 1
fi
echo "Extracted $tarball successfully"
cd $tarball

########################
# Specific build steps #
########################
sed '361 s/{/\\{/' -i bin/autoscan.in
./configure --prefix=/usr
make
# The test suite is broken with bash 5 and libtool 2.4.3
# Uncomment the following line to run anyway
# make check
make install

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
