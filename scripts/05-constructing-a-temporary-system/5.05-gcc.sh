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
tarball="gcc-8.2.0"

########################
# Generic build steps  #
########################
cd $LFS/sources
tar -xvf $tarball.tar.xz
if [ ! -d $LFS/sources/$tarball ]; then
  echo "ERROR: Unable to extract tarball named $tarball, check the file extensions"
  exit 1
fi
cd $tarball

########################
# Specific build steps #
########################
tar -xf ../mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

for file in gcc/config/{linux,i386/linux{,64}}.h; do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
    -e 's@/usr@/tools@g' $file.orig >$file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >>$file
  touch $file.orig
done

case $(uname -m) in
x86_64)
  sed -e '/m64=/s/lib64/lib/' \
    -i.orig gcc/config/i386/t-linux64
  ;;
esac

mkdir -v build
cd build

../configure \
  --target=$LFS_TGT \
  --prefix=/tools \
  --with-glibc-version=2.11 \
  --with-sysroot=$LFS \
  --with-newlib \
  --without-headers \
  --with-local-prefix=/tools \
  --with-native-system-header-dir=/tools/include \
  --disable-nls \
  --disable-shared \
  --disable-multilib \
  --disable-decimal-float \
  --disable-threads \
  --disable-libatomic \
  --disable-libgomp \
  --disable-libmpx \
  --disable-libquadmath \
  --disable-libssp \
  --disable-libvtv \
  --disable-libstdcxx \
  --enable-languages=c,c++

make
make install
#########################
# Generic cleanup steps #
#########################
cd $LFS/sources
rm -rf $tarball
