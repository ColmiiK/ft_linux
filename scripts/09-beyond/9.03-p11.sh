#!/bin/bash

# URL https://www.linuxfromscratch.org/blfs/view/8.4/postlfs/p11-kit.html
# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='p11-kit-0.23.15'

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

sed '20,$ d' -i trust/trust-extract-compat.in &&
  cat >>trust/trust-extract-compat.in <<"EOF"

# Copy existing anchor modifications to /etc/ssl/local
/usr/libexec/make-ca/copy-trust-modifications

# Generate a new trust store
/usr/sbin/make-ca -f -g

EOF
./configure --prefix=/usr \
  --sysconfdir=/etc \
  --with-trust-paths=/etc/pki/anchors &&
  make
make install &&
  ln -s /usr/libexec/p11-kit/trust-extract-compat \
    /usr/bin/update-ca-certificates
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
