#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='gcc-8.2.0'

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
#########################
case $(uname -m) in
x86_64)
  sed -e '/m64=/s/lib64/lib/' \
    -i.orig gcc/config/i386/t-linux64
  ;;
esac

rm -f /usr/lib/gcc

mkdir -v build
cd build

SED=sed \
  ../configure --prefix=/usr \
  --enable-languages=c,c++ \
  --disable-multilib \
  --disable-bootstrap \
  --disable-libmpx \
  --with-system-zlib

make

ulimit -s 32768

rm ../gcc/testsuite/g++.dg/pr83239.C

chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make -k check"

../contrib/test_summary

make install

ln -sv ../usr/bin/cpp /lib

ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.2.0/liblto_plugin.so \
  /usr/lib/bfd-plugins/

echo 'int main(){}' >dummy.c
cc dummy.c -v -Wl,--verbose &>dummy.log
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log

grep -B4 '^ /usr/include' dummy.log

grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g'

grep "/lib.*/libc.so.6 " dummy.log

grep found dummy.log

rm -v dummy.c a.out dummy.log

mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
