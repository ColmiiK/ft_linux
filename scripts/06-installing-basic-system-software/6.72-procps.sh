#!/bin/bash

# URL https://www.linuxfromscratch.org/museum/lfs-museum/8.4/LFS-BOOK-8.4-HTML/chapter06/procps-ng.html

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='procps-ng-3.3.15'

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
./configure --prefix=/usr \
  --exec-prefix= \
  --libdir=/usr/lib \
  --docdir=/usr/share/doc/procps-ng-3.3.15 \
  --disable-static \
  --disable-kill
make
# sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
# sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
# rm testsuite/pgrep.test/pgrep.exp
# make check
make install
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
