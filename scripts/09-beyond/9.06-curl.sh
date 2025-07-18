#!/bin/bash

# URL https://www.linuxfromscratch.org/blfs/view/8.4/basicnet/curl.html
# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='curl-7.64.0'

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

./configure \
  --prefix=/usr \
  --disable-static \
  --enable-threaded-resolver \
  --with-ca-path=/etc/ssl/certs
make
make install
rm -rf docs/examples/.deps
find docs \( -name Makefile\* -o -name \*.1 -o -name \*.3 \) -exec rm {} \;
install -v -d -m755 /usr/share/doc/curl-7.64.0
cp -v -R docs/* /usr/share/doc/curl-7.64.0

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
