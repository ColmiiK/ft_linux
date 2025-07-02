<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Making the LFS system bootable

It's time to make the LFS system bootable. First, let's start by creating the `fstab` file.

## Creating the `/etc/fstab` file

This file is used to determine where file systems are mounted by default.
Create a new file system table like this.
Replace `<xxx>`, `<yyy>` and `<fff>` with the appropriate options for your system.

```shell
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/<xxx>     /            <fff>    defaults            1     1
/dev/<yyy>     swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF
```

In my case, `<fff>` is `ext4`, `<xxx>` is `sbd3` and `<yyy>` is `sbd2`.
Here it is the complete command in my case.

```shell
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sdb3      /            ext4     defaults            1     1
/dev/sbd2      swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF
```

## Linux kernel

- 4.4 - 66 SBU (typically about 6 SBU)
- 960 - 4250 MB (typically about 1100 MB)

First, make sure the kernel tree is clean.

```shell
make mrproper
```

Then, run this command to generate a generic starting point based on your system's architecture.

```shell
make defconfig
```

Then, run this command to configure the kernel.
This will open a configuration menu.
To learn about each configuration option, refer to the kernel's readme.

```shell
make menuconfig
```

Again, this configuration is quite in depth, so I recommend reading on the LFS about the options.

Now compile and install the modules if the kernel configuration uses them.

```shell
make
make modules_install
```

If the host has a different `/boot` mount it to `$LFS/boot` since we need to copy some files.
Do this as the root user in the host system, not chroot.

```shell
mount --bind /boot /mnt/lfs/boot
```

Copy files to the boot partition.
Fill in your student login as required by the subject.

```shell
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-4.19.325-<student_login>
cp -iv System.map /boot/System.map-4.19.325
cp -iv .config /boot/config-4.19.325
install -d /usr/share/doc/linux-4.19.325
cp -r Documentation/* /usr/share/doc/linux-4.19.325
```

To make sure the Linux modules are loaded correctly, run this command to create the `usb.conf` file.

```shell
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
```

## Using GRUB to set up the boot process

**Important**: configuring GRUB incorrectly will render your system unusable.

Since we're doing it in a VM, we ball.

Install the GRUB files to your boot, where `<xxx>` is the boot partition of your LFS.

```shell
grub-install /dev/<xxx>
```

Generate a `grub.cfg` file.

```shell
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux 4.19.325-alvega-g" {
        linux   /vmlinuz-4.19.325-alvega-g root=/dev/sbd1 ro
}
EOF
```
