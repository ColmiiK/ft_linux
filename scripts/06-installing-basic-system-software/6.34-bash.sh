#!/bin/bash

# URL https://www.linuxfromscratch.org/museum/lfs-museum/8.4/LFS-BOOK-8.4-HTML/chapter06/bash.html

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='bash-5.0'

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
  --docdir=/usr/share/doc/bash-5.0 \
  --without-bash-malloc \
  --with-installed-readline
make
# chown -Rv nobody .
# su nobody -s /bin/bash -c "PATH=$PATH HOME=/home make tests"
make install
mv -vf /usr/bin/bash /bin
# exec /bin/bash --login +h

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
