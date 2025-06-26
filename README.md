# ft_linux

## Goals

- Build a Linux Kernel
- Install binaries
- Implement a filesystem hierarchy compliant with [standards](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)
- Connect to the internet

## General instructions

### Resources

- [The Bible](https://www.linuxfromscratch.org/lfs/view/stable/index.html) (no, not that one)
- [Autotools](https://www.gnu.org/software/automake/manual/html_node/index.html#SEC_Contents)

### Instructions

- Use a virtual machine
- Read [this](https://pubs.opengroup.org/onlinepubs/9699919799/) and [that](https://refspecs.linuxfoundation.org/lsb.shtml). Keep those standards in mind. You won't be graded on it, but it's good practice
- Use a kernel version 4.x, stable or not
- Kernel sources must be in `/usr/src/kernel-$(version)`
- Use at least 3 partitions, although you can add more:
  - root
  - /boot
  - swap
- Implement a `kernel_module` loader, like `udev`
- The kernel version must contain your student login, i.e. `Linux Kernel 4.1.2-$(login)`
- The distribution hostname must be your student login
- Either 32 or 64 bit
- Use software for central management and configuration, like `SysV` or `SystemD`
- Must boot with a bootloader like `LILO` or `GRUB`
- The kernel binary located in `/boot` must be named `vmlinuz-<linux_version>-<student_login>`.
  Adapt your bootloader accordingly

## Mandatory part

### Packages to install

Some of the packages are examples. Feel free to change them to any equivalent you like

- `Acl`
- `Attr`
- `Autoconf`
- `Automake`
- `Bash`
- `Bc`
- `Binutils`
- `Bison`
- `Bzip2`
- `Check`
- `Coreutils`
- `DejaGNU`
- `Diffutils`
- `Eudev`
- `E2fsprogs`
- `Expat`
- `Expect`
- `File`
- `Findutils`
- `Flex`
- `Gawk`
- `GCC`
- `GDBM`
- `Gettext`
- `Glibc`
- `GMP`
- `Gperf`
- `Grep`
- `Groff`
- `GRUB`
- `Gzip`
- `Iana-Etc`
- `Inetutils`
- `Intltool`
- `IPRoute2`
- `Kbd`
- `Kmod`
- `Less`
- `Libcap`
- `Libpipeline`
- `Libtool`
- `M4`
- `Make`
- `Man-DB`
- `Man-pages`
- `MPC`
- `MPFR`
- `Ncurses`
- `Patch`
- `Perl)`
- `Pkg-config`
- `Procps`
- `Psmisc`
- `Readline`
- `Sed`
- `Shadow`
- `Sysklogd`
- `Sysvinit`
- `Tar`
- `Tcl`
- `Texinfo`
- `Time Zone Data`
- `Udev-lfs Tarball`
- `Util-linux`
- `Vim`
- `XML::Parser`
- `Xz Utils`
- `Zlib`

## Bonus part

Install whatever you want, make the system yours.
Bonus points for:

- X server
- Window managers and desktop environments like i3, GNOME, etc.
