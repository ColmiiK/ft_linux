#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball="glibc-2.29"

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
patch -Np1 -i ../glibc-2.29-fhs-1.patch

ln -sfv /tools/lib/gcc /usr/lib

case $(uname -m) in
i?86)
  GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/8.2.0/include
  ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
  ;;
x86_64)
  GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
  ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
  ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
  ;;
esac

rm -f /usr/include/limits.h

mkdir -v build
cd build

CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
  ../configure --prefix=/usr \
  --disable-werror \
  --enable-kernel=3.2 \
  --enable-stack-protector=strong \
  libc_cv_slibdir=/lib
unset GCC_INCDIR

make

case $(uname -m) in
i?86) ln -sfnv $PWD/elf/ld-linux.so.2 /lib ;;
x86_64) ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac
echo "Run the tests? [Y,n]"
read input
if [[ $input == "Y" || $input == "y" ]]; then
  make check
fi

touch /etc/ld.so.conf

sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make install

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2>/dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2>/dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS

make localedata/install-locales

cat >/etc/nsswitch.conf <<"EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2018i.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica \
  asia australasia backward pacificnew systemv; do
  zic -L /dev/null -d $ZONEINFO ${tz}
  zic -L /dev/null -d $ZONEINFO/posix ${tz}
  zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

cp -v /usr/share/zoneinfo/Europe/Madrid /etc/localtime

cat >/etc/ld.so.conf <<"EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF

cat >>/etc/ld.so.conf <<"EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
