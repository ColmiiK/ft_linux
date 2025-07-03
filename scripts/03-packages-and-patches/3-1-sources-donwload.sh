#!/bin/bash

# Ensure user is root
if ! whoami | grep -q "root"; then
  echo "Please become root"
  su
fi

# Create sources directory
mkdir -v $LFS/sources

# Ensure the directory is writable and sticky
chmod -v a+wt $LFS/sources

# Download curl if not installed
if ! command -v curl >/dev/null 2>&1; then
  echo "curl not found, installing..."
  apt install curl
fi

# Get wget-list and md5sums
curl https://www.linuxfromscratch.org/museum/lfs-museum/8.4/LFS-BOOK-8.4-HTML/wget-list >/tmp/wget-list
curl https://www.linuxfromscratch.org/museum/lfs-museum/8.4/LFS-BOOK-8.4-HTML/md5sums >/tmp/md5sums

# Download packages to sources
# wget --input-file=/tmp/wget-list --continue --directory-prefix=$LFS/sources

# Download missing packages

# Check for existing files first
wget https://github.com/libexpat/libexpat/releases/download/R_2_2_6/expat-2.2.6.tar.bz2 --directory-prefix=$LFS/sources
wget https://www.linuxfromscratch.org/museum/lfs-museum/8.4/lfs-bootscripts-20180820.tar.bz2 --directory-prefix=$LFS/sources
wget https://www.kernel.org/pub/linux/docs/man-pages/Archive/man-pages-4.16.tar.xz --directory-prefix=$LFS/sources
wget https://repository.timesys.com/buildsources/p/psmisc/psmisc-23.2/psmisc-23.2.tar.xz --directory-prefix=$LFS/sources
wget https://zlib.net/fossils/zlib-1.2.11.tar.gz --directory-prefix=$LFS/sources

# Check hashes of sources
pushd $LFS/sources
md5sum -c /tmp/md5sums
popd
