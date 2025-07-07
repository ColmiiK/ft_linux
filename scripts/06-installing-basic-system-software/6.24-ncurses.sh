#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='ncurses-6.1'

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

sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in

./configure --prefix=/usr \
  --mandir=/usr/share/man \
  --with-shared \
  --without-debug \
  --without-normal \
  --enable-pc-files \
  --enable-widec

make

make install

mv -v /usr/lib/libncursesw.so.6* /lib

ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

for lib in ncurses form panel menu; do
  rm -vf /usr/lib/lib${lib}.so
  echo "INPUT(-l${lib}w)" >/usr/lib/lib${lib}.so
  ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done

rm -vf /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" >/usr/lib/libcursesw.so
ln -sfv libncurses.so /usr/lib/libcurses.so

mkdir -v /usr/share/doc/ncurses-6.1
cp -v -R doc/* /usr/share/doc/ncurses-6.1

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
