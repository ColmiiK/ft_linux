<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Chroot and temporary tools

Now that the circular dependencies have been solved,
we can build the tools inside a `chroot` environment,
completely isolated from the host except for the kernel.
To achieve this, we will be creating a "Virtual Kernel File System",
so we can access the only necessary part of our host inside chroot.

**Important**: from now on, the commands must be run as `root`, NOT as `lfs`.
Make sure `$LFS` is set for root.

## Changing ownership

Currently, all files inside `$LFS` are owned by `lfs`.
If we keep them like that, once we are done, they will be owned
by a user ID without an account, so if we created one account,
it could have that user ID, creating a serious security risk.

Let's change the ownership of all files inside `$LFS` to root to fix this issue.

```shell
chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac
```

## Preparing virtual kernel file systems

Applications in userspace use file systems created by the kernel to communicate with it.
These are mounted in memory, they have no disk space. We need to mount them inside the `$LFS`
directories so we can use them in the chroot.

```shell
mkdir -pv $LFS/{dev,proc,sys,run}
```

On a normal boot, the kernel mounts the `devtmpfs` file system on `/dev`.
The udev daemon eases the work of administrators by changing ownership and permissions
of the device nodes created by the kernel. If the host kernel supports `devtmpfs`,
we can simply mount it at `$LFS/dev` and let the kernel do it's thing.
But since some lack this support, we can manually mount and populate it.
We do this with a "bind" mount, a directory that is visible at some other location.

```shell
mount -v --bind /dev $LFS/dev
```

Now mount the remaining virtual kernel file systems.

```shell
mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
```

In some hosts, `/dev/shm` is a symlink to `/run/shm`, in others it's a mount point
for a `tmpfs`. We can fix this conditionally.

```shell
if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi
```

## Entering chroot

Now that we have everything we need, we can enter chroot to finish our LFS.
As root, run this command to enter the environment populated only with
the termporary tools we compiled before.

```shell
chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login
```

After this point, we don't need to use the `$LFS` variable since all the work
will be contained to the LFS file system.
Note how `/tools/bin` is not in `$PATH`, we will not be using the toolchain anymore.
Also, the `I have no name!` prompt is normal, the `/etc/passwd` file has not been created yet.

## Creating directories

Time to create the full directory structure.
Create some root directories first.

```shell
mkdir -pv /{boot,home,mnt,opt,srv}
```

Create the subdirectories.

```shell
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
```

Since the directories are created with mode 755, some folders are created with different
permissions, for security reasons.

We **could** create more directories, but this structure is compliant with FHS.
Since this is a requirement of the subject, we'll stick to it.

## Creating essential files and symlinks

Linux maintains a list of mounted systems in `/etc/mtab`, exposed to the user with the `/proc` filesystem.
Let's make sure the programs are able to find this `/etc/mtab`.

```shell
ln -sv /proc/self/mounts /etc/mtab
```

Create a basic `/etc/hosts` that will be referenced later.

```shell
cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF
```

For the root user to be recognized and able to log in,
there must be entries in `/etc/passwd` and `/etc/group`.

Create the `/etc/passwd` file first.

```shell
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF
```

We'll set the password for root later.

Create the `/etc/group` file second.

```shell
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF
```

All of these groups are not part of a standard, but they are requirements for the configuration
of udev later. They are also conventions employed by existing Linux distros, like GID 5 for tty.

Later we'll need a regular user for testing purposes,
let's create it here and then we will delete it at the end of the chapter.

```shell
echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
echo "tester:x:101:" >> /etc/group
install -o tester -d /home/tester
```

To fix the pesky prompt, start a new shell now that the passwd and group files exist.

```shell
exec /usr/bin/bash --login
```

A lot of programs write logs to record information, but they won't do this if the files don't exist first.
Initialize the logs with the proper permissions.

```shell
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
```

Now we'll go back to installing a few tools.

## Gettext

- 1.3 SBU
- 349 MB

Again, go to `$LFS/sources`, extract, cd in to the folder before advancing.

Prepare for compilation.

```shell
./configure --disable-shared
```

Compile.

```shell
make
```

Install `msgfmt`, `msgmerge` and `xgettext`.

```shell
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
```

## Bison

- 0.2 SBU
- 58 MB

Prepare for compilation.

```shell
./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
```

Compile and install.

```shell
make
make install
```

## Perl

- 0.6 SBU
- 285 MB

Prepare for compilation.

```shell
sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.40/core_perl     \
             -D archlib=/usr/lib/perl5/5.40/core_perl     \
             -D sitelib=/usr/lib/perl5/5.40/site_perl     \
             -D sitearch=/usr/lib/perl5/5.40/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl
```

Compile and install.

```shell
make
make install
```

## Python

- 0.5 SBU
- 634 MB

**Important**: Extract the package with an uppercase "P" (Python-X.X.X),
not the package with a lowercase "p".

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
```

Compile and install.

```shell
make
make install
```

Note that some modules can't be built yet.
As long as the top `make` command didn't fail, you're good.

## Texinfo

- 0.2 SBU
- 152 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile and install.

```shell
make
make install
```

## Util-linux

- 0.2 SBU
- 182 MB

The FHS recommends the `/var/lib/hwclocl` for the `adjtime` file, instead of `/etc`.
Create it.

```shell
mkdir -pv /var/lib/hwclock
```

Prepare for compilation.

```shell
./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.4
```

Compile and install.

```shell
make
make install
```

## Cleaning up and saving the temporary system

Remove the current docs so they don't end up in the final system.

```shell
rm -rf /usr/share/{info,man,doc}/*
```

On a modern Linux system, the libtool `.la` files are only useful for `libtdl`.
Since no libraries are loaded by `libtdl` in LFS, remove them to prevent issues.

```shell
find /usr/{lib,libexec} -name \*.la -delete
```

The current system size should be around 3 GB, but the `/tools` directory is no longer needed.
Remove it and save about 1 GB of disk space.

```shell
rm -rf /tools
```

In case something goes awfully wrong in later stages, is wise to backup your system since
usually the best way of recovering is starting over.
Note, however, that this is optional but highly recommended.
Exit the chroot environment.

```shell
exit
```

These instructions will be executed as root in your host system.
Be extra careful with the commands.
Once again, make sure that the `$LFS` variable is set.

Unmount the virtual file systems.

```shell
mountpoint -q $LFS/dev/shm && umount $LFS/dev/shm
umount $LFS/dev/pts
umount $LFS/{sys,proc,run,dev}
```

Make sure you have at least 1 GB of free disk space.

This will compress and back up the LFS, leaving the `.tar` in your root `$HOME`.

```shell
cd $LFS
tar -cJpf $HOME/lfs-temp-tools-12.3.tar.xz .
```

This can take a long time, even 10 minutes on a fast system.

If you need to restore your system, you can extract the file and copy it.

**VERY IMPORTANT**: if you run `rm -rf ./*` as root and don't cd into the `$LFS`
directory or the `$LFS` variable is not set, very, very bad things will happen.
You have been warned.

```shell
cd $LFS
rm -rf ./*
tar -xpf $HOME/lfs-temp-tools-12.3.tar.xz
```

Remount the filesystem if they aren't mounted, re-enter the chroot environment and continue.
