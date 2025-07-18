#!/bin/bash

# URL https://www.linuxfromscratch.org/blfs/view/8.4/general/git.html

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='git-2.20.1'

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

./configure --prefix=/usr --with-gitconfig=/etc/gitconfig
make
# make html
# make man
make install
# make install-man
# make htmldir=/usr/share/doc/git-2.20.1 install-html
tar -xf ../git-manpages-2.20.1.tar.xz \
  -C /usr/share/man --no-same-owner --no-overwrite-dir
mkdir -vp /usr/share/doc/git-2.20.1
tar -xf ../git-htmldocs-2.20.1.tar.xz \
  -C /usr/share/doc/git-2.20.1 --no-same-owner --no-overwrite-dir
find /usr/share/doc/git-2.20.1 -type d -exec chmod 755 {} \;
find /usr/share/doc/git-2.20.1 -type f -exec chmod 644 {} \;
mkdir -vp /usr/share/doc/git-2.20.1/man-pages/{html,text}
mv /usr/share/doc/git-2.20.1/{git*.txt,man-pages/text}
mv /usr/share/doc/git-2.20.1/{git*.,index.,man-pages/}html
mkdir -vp /usr/share/doc/git-2.20.1/technical/{html,text}
mv /usr/share/doc/git-2.20.1/technical/{*.txt,text}
mv /usr/share/doc/git-2.20.1/technical/{*.,}html
mkdir -vp /usr/share/doc/git-2.20.1/howto/{html,text}
mv /usr/share/doc/git-2.20.1/howto/{*.txt,text}
mv /usr/share/doc/git-2.20.1/howto/{*.,}html
sed -i '/^<a href=/s|howto/|&html/|' /usr/share/doc/git-2.20.1/howto-index.html
sed -i '/^\* link:/s|howto/|&html/|' /usr/share/doc/git-2.20.1/howto-index.txt

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
