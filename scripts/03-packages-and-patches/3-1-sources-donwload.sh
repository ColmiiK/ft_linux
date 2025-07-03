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
wget --input-file=/tmp/wget-list --continue --directory-prefix=$LFS/sources

# Check hashes of sources
pushd $LFS/sources
md5sum -c /tmp/md5sums
popd
