#!/bin/bash

# URL https://www.linuxfromscratch.org/blfs/view/8.4/postlfs/make-ca.html
# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='make-ca-1.2'

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

make install
/usr/sbin/make-ca -g
ln -sfv /etc/pki/tls/certs/ca-bundle.crt \
  /etc/ssl/ca-bundle.crt
# install -vdm755 /etc/cron.weekly &&
#   cat >/etc/cron.weekly/update-pki.sh <<"EOF" &&
#
# #!/bin/bash
# /usr/sbin/make-ca -g
#
# EOF
#   chmod 754 /etc/cron.weekly/update-pki.sh
# install -vdm755 /etc/ssl/local &&
#   wget http://www.cacert.org/certs/root.crt &&
#   wget http://www.cacert.org/certs/class3.crt &&
#   openssl x509 -in root.crt -text -fingerprint -setalias "CAcert Class 1 root" \
#     -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#     >/etc/ssl/local/CAcert_Class_1_root.pem &&
#   openssl x509 -in class3.crt -text -fingerprint -setalias "CAcert Class 3 root" \
#     -addtrust serverAuth -addtrust emailProtection -addtrust codeSigning \
#     >/etc/ssl/local/CAcert_Class_3_root.pem
# install -vdm755 /etc/ssl/local &&
#   openssl x509 -in /etc/ssl/certs/Makebelieve_CA_Root.pem \
#     -text \
#     -fingerprint
# -setalias "Disabled Makebelieve CA Root" \
#   -addreject serverAuth \
#   -addreject emailProtection \
#   -addreject codeSigning \
#   >/etc/ssl/local/Disabled_Makebelieve_CA_Root.pem &&
#   /usr/sbin/make-ca -r -f

#########################
# Generic cleanup steps #
#########################
cd /sources
rm -rf $tarball
