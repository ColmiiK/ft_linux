#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

################
# Tarball name #
################
tarball='linux-4.20.12'

########################
# Generic build steps  #
########################
cd /sources
if [ ! -d /sources/$tarball ]; then
  echo "Extracting $tarball..."
  tar -xvf $tarball.tar.xz >/dev/null 2>&1
  tar -xvf $tarball.tar.gz >/dev/null 2>&1
  tar -xvf $tarball.tar.bz2 >/dev/null 2>&1
fi
cd $tarball

########################
# Specific build steps #
########################
echo "RUN
  make mrproper"
echo "RUN
  make defconfig"
echo "Ensure these options are set:
Device Drivers  --->
  Generic Driver Options  --->
   [ ] Support for uevent helper [CONFIG_UEVENT_HELPER]
   [*] Maintain a devtmpfs filesystem to mount at /dev [CONFIG_DEVTMPFS]

Kernel hacking  --->
       Choose kernel unwinder (Frame pointer unwinder)  ---> [CONFIG_UNWINDER_FRAME_POINTER]
"
echo "RUN
  make menuconfig"
echo "RUN
  make"
echo "RUN
  make modules_install"
echo "RUN
  cp -iv arch/x86/boot/bzImage /boot/vmlinuz-4.20.12-<your_student_login>"
echo "RUN
  cp -iv System.map /boot/System.map-4.20.12"
echo "RUN
  cp -iv .config /boot/config-4.20.12"
echo "RUN
  install -d /usr/share/doc/linux-4.20.12
  cp -r Documentation/* /usr/share/doc/linux-4.20.12"
echo "RUN
  install -v -m755 -d /etc/modprobe.d
  cat > /etc/modprobe.d/usb.conf << EOF
  # Begin /etc/modprobe.d/usb.conf

  install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
  install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

  # End /etc/modprobe.d/usb.conf
  EOF
"

#########################
# Generic cleanup steps #
#########################
echo "Clean up process:
cd /sources
rm -rf $tarball
"
