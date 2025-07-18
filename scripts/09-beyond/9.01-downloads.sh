#!/bin/bash

# Ensure user is root
if ! whoami | grep -q "root"; then
  echo "ERROR: Please become root: 'su'"
  exit 1
fi

# We will install several packages needed for the evaluation process

if [ ! -f $LFS/sources/wget-1.20.1.tar.gz ]; then
  wget https://ftp.gnu.org/gnu/wget/wget-1.20.1.tar.gz --directory-prefix=$LFS/sources
fi

if [ ! -f $LFS/sources/make-ca-1.2.tar.gz ]; then
  wget https://github.com/djlucas/make-ca/archive/refs/tags/v1.2.tar.gz --directory-prefix=$LFS/sources
  mv $LFS/sources/v1.2.tar.gz $LFS/sources/make-ca-1.2.tar.gz
fi

if [ ! -f $LFS/sources/p11-kit-0.23.15.tar.gz ]; then
  wget https://github.com/p11-glue/p11-kit/releases/download/0.23.15/p11-kit-0.23.15.tar.gz --directory-prefix=$LFS/sources
fi

if [ ! -f $LFS/sources/libtasn1-4.13.tar.gz ]; then
  wget https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.13.tar.gz --directory-prefix=$LFS/sources
fi

if [ ! -f $LFS/sources/curl-7.64.0.tar.xz ]; then
  wget https://curl.haxx.se/download/curl-7.64.0.tar.xz --directory-prefix=$LFS/sources
fi

if [ ! -f $LFS/sources/git-2.20.1.tar.xz ]; then
  wget https://www.kernel.org/pub/software/scm/git/git-2.20.1.tar.xz --directory-prefix=$LFS/sources
  wget https://www.kernel.org/pub/software/scm/git/git-manpages-2.20.1.tar.xz --directory-prefix=$LFS/sources
  wget https://www.kernel.org/pub/software/scm/git/git-htmldocs-2.20.1.tar.xz --directory-prefix=$LFS/sources
fi

pushd $LFS/sources
md5sum -c <<<"f6ebe9c7b375fc9832fb1b2028271fb7 wget-1.20.1.tar.gz"
# md5sum -c <<<"5b68cf77b02d5681f8419b8acfd139c0 make-ca-1.2.tar.gz"
md5sum -c <<<"c4c3eecfe6bd6e62e436f62b51980749 p11-kit-0.23.15.tar.gz"
md5sum -c <<<"ce2ba4d3088119b48e7531a703669c52 libtasn1-4.13.tar.gz"
md5sum -c <<<"d14fe778e9f00399445d9525117e25a3 curl-7.64.0.tar.xz"
md5sum -c <<<"5fb4ff92b56ce3172b99c1c74c046c1a git-2.20.1.tar.xz"
popd
