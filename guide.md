<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# LFS

All of the information in this guide comes from [Linux From Scratch](https://www.linuxfromscratch.org/lfs/view/stable/index.html). I'm adapting it slightly for the purposes of completing the `ft_linux` project.

## Setup a VM

The VM should have at least 4 cores and 8GB of RAM.
If these requirements are not met, the time to build the packages will be slower,
but otherwise it will work.

## Prepare the Host System

### Software

Execute the `version-check.sh` script to check for dependencies.

```shell
bash version-check.sh
```

Don't proceed until all packages and aliases are set.

### Partitions

We need at least:

- A boot partition
- A root (/) partition
- A swap partition

In terms of size, 10GB would be for a minimal system, 30GB would be for a system with space for growth.
I decided to use 30GB, with 512MB for boot, 4GB for swap and the rest for root.

First, add a virtual disk to the VM.
Then, we will partition the disk with `fdisk`

```shell
fdisk <disk route>
```

Then inside `fdisk`, follow the instructions for creating a new partition:

```shell
fdisk> n
fdisk> Partition number: <Enter>
fdisk> First sector: <Enter>
fdisk> Last sector: <Desired space for the partition, i.e. +512MB or +4GB>
```

For the last partition (root) we can just select the default last sector,
because that will be the rest of the drive.
Once you are done, save the changes

```shell
fdisk> w
```

And check the changes with `lsblk` or `fdisk -l`

```shell
$> lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   20G  0 disk
 sda1   8:1    0   19G  0 part /
 sda2   8:2    0    1K  0 part
 sda5   8:5    0  975M  0 part [SWAP]
sdb      8:16   0   30G  0 disk
 sdb1   8:17   0  488M  0 part
 sdb2   8:18   0  3.7G  0 part
 sdb3   8:19   0 25.8G  0 part
sr0     11:0    1 58.5M  0 rom
```

In my case, `sdb` is the partition we just created.

Also, we can create more partitions if we want, but don't get fancy.

Now, let's format the partitions appropriately. We'll use `ext4` for simplicity.

```shell
mkfs -v -t ext4 <boot partition>
mkswap <swap partition>
mkfs -v -t ext4 <root partition>
```

In my case, the partitions are `/dev/sdbX`, either 1, 2 or 3.

Before we continue, make sure that your `LFS` environment variable is set properly FOR THE ROOT USER.

```shell
echo $LFS
```

To achieve this, add it in the `/etc/environment` file.

Also, set the `umask` for the system to `022`. This will ensure that the files are created with
proper permissions.

```shell
umask 022
```

Let's mount the partitions. First, create a mount point, then mount them.

```shell
mkdir -p $LFS
mount -v -t ext4 <root partition> $LFS
mkdir -p $LFS/boot
mount -v -t ext4 <boot partition> $LFS/boot
swapon -v <swap partition>
```

Set the ownership of the `$LFS` directory to root and the file permissions.

```shell
chown root:root $LFS
chmod 755 $LFS
```

And we're set to start installing packages.
**Important**: if you restart your computer at any point throughout the LFS process,
you will need to remount the LFS partition each time. To fix this, you can add the
following line to the host's `/etc/fstab` file. You can find your partitions UUID
by running `blkid`.

```shell
UUID=<root partition uuid>  /mnt/lfs      ext4   defaults,nofail 0 0
UUID=<boot partition uuid>  /mnt/lfs/boot ext4   defaults,nofail 0 0
UUID=<swap partition uuid>  none          swap   sw,nofail       0 0
```

## Packages

Before we start downloading tarballs, we need a place to store and work with them.

```shell
mkdir -v $LFS/sources
```

Modify the permissions to make it writable and sticky, meaning that only the owner can delete files inside it.

```shell
chmod -v a+wt $LFS/sources
```

Now we can start downloading packages. You could download each tarball individually (not very programmer of you)
or you could use a `wget-list-sysv` file like the one provided in the LFS book. It has all of the packages
required by the subject, so convenient. You can get it right [here](https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv).

```shell
curl https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv > wget-list-sysv
```

Download all the packages before proceeding, it's going to take a little while.
The total download size should be around 500MB.

```shell
wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
```

LFS also provides us with a `md5sums` file to check the authenticity of everything we just downloaded.

```shell
curl https://www.linuxfromscratch.org/lfs/view/stable/md5sums > $LFS/sources/md5sums
pushd $LFS/sources
 md5sum -c md5sums
popd
```

Also, make sure that the owner of these files is root. If they aren't, fix it.

```shell
chown root:root $LFS/sources/*
```

**Important note**: in our subject, we are required to use a kernel version 4.x.
The kernel used in LFS is the latest one, which is no good for us. Delete that kernel version and
get the tarball for a 4.x kernel.

```shell
rm $LFS/sources/linux-6.13.4.tar.xz
wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.9.tar.gz
```

I also had to manually download a different `expat` version than the provided one.
Mileage may vary.

```shell
wget https://prdownloads.sourceforge.net/expat/expat-2.7.1.tar.xz
```

We now have all the packages ready for our very own Linux.

## Final preparations

We will start by populating the LFS file system.

```shell
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
    ln -sv usr/$i $LFS/$i
   done
case $(uname -m) in
    x86_64) mkdir -pv $LFS/lib64 ;;
   esac
```

The programs we will compile later need to be compiled with a cross-compiler, we will install this tool in a
special directory.

```shell
mkdir -pv $LFS/tools
```

To prevent us from bricking the system, the packages we will be building next will be done with an
unprivileged user. Create one if needed. To simplify things, we will create a `lfs` user that
belongs to a `lfs` group.

```shell
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
```

You can set a password for the user if you want, so you don't need to be root to change to it.

```shell
passwd lfs
```

Now we will give the `lfs` user full access and ownership of the files under `$LFS`.

```shell
chown -v lfs $LFS/{usr{,/*},var,etc,tools}
case $(uname -m) in
    x86_64) chown -v lfs $LFS/lib64 ;;
   esac
```

Log in as the `lfs` user with a login shell. The purpose of this is to have a clean slate to create
our working environment, without potentially hazardous environment variables from the host.

```shell
su - lfs
```

Let's set a working environment.

```shell
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
```

Since a login shell only reads the `.bash_profile` file, with this we create a non-login shell with only the
`HOME`, `TERM` and `PS1` variables set. In this new non-login shell, we can specify a `.bashrc` to set
the new variables we do want.

```shell
cat > ~/.bashrc << "EOF"
set +h # turn of bash hash
umask 022 # set the mask as we explained before
LFS=/mnt/lfs # set the LFS variable
LC_ALL=POSIX # set the LC_ALL variable for localization
LFS_TGT=$(uname -m)-lfs-linux-gnu # sets a variable for target compilation
PATH=/usr/bin # set PATH
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi # create symbolic link
PATH=$LFS/tools/bin:$PATH # use the our cross compiler first
CONFIG_SITE=$LFS/usr/share/config.site # prevent host contamination of configs
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE # export everything
EOF
```

To speed up the compilation, we will set a Makefile flag for it to use all available logical cores of our machine.

```shell
cat >> ~/.bashrc << "EOF"
export MAKEFLAGS=-j$(nproc)
EOF
```

To ensure the environment is set, force the shell to read the new user profile.

```shell
source ~/.bash_profile
```

With this finished, we have all we need to build our cross-compiler, the first step in our chain.

Our objective is to remove ourselves further and further from our host machine. To achieve this,
first we will create a set of temporary tools that will allow us to isolate the rest of the compilation.
These late stages will be run in a `chroot` environment, to distance ourselves from the host even more.
There is a lot to unpack here, so I recommend reading up on the chapter itself in the [LFS](https://www.linuxfromscratch.org/lfs/view/stable/partintro/toolchaintechnotes.html).

**Important**: This is the final check before compilation. Be sure that, in the host system:

- `bash` is the shell in use
- `sh` is a symbolic link to `bash`
- `/usr/bin/awk` is a symbolic link to `gawk`
- `/usr/bin/yacc` is a symbolic link to `bison`

Also check that the `$LFS` variable is set in the `lfs` user.

```shell
echo $LFS
```

This is a synopsis of the build process:

- Place all sources in a directory accessible from the `chroot` like `$LFS/sources`
- Change to the `$LFS/sources` directory
- For each package:
  - Extract the package with `tar` and only with `tar`
  - Change to the directory created when the package was extracted
  - Follow the instructions for building the package
  - Change back to the sources directory when building is complete
  - Delete the extracted source directory unless instructed otherwise

## Compiling a Cross-Toolchain

These programs will be installed under `$LFS/tools` to keep them separate.
The libraries will instead be installed in their final location.

**Important**: Building all of these tools takes time. Furthermore, this time depends on the
host machine. Therefore, we will measure the installation time in **SBUs** (Standard Build Unit).
This is the time that it takes the first package, Binutils, to build.
If a package has a build time of 5 SBUs and Binutils took, in your machine, 1 minute to build,
that package will, on average, take 5 minutes.

A lot of the configuration commands need specific flags,
if you want a deeper understanding of what those flags do,
check the corresponding page of the LFS.

### Binutils - Pass 1

- 1 SBU
- 677 MB

I'll describe the building process for this first package in depth, with the next ones I'll skip the
repeated instructions, such as unpacking.

```shell
cd $LFS/sources
tar -xvf binutils-2.44.tar.xz
cd binutils-2.44
```

The Binutils docs recommend creating a specific build directory.

```shell
mdkir -v build
cd build
```

Now, prepare Binutils for compilation. To check for SBU, wrap the commands in `time`.

```shell
time { ../configure --prefix=$LFS/tools \
                --with-sysroot=$LFS \
                --target=$LFS_TGT \
                --disable-nls \
                --enable-gprofng=no \
                --disable-werror \
                --enable-new-dtags \
                --enable-default-hash-style=gnu && \
  make && make install; }
```

Finally, we delete the extracted directory and move on with the next tool.

```shell
cd ../..
rm -rf binutils-2.44
```

### GCC - Pass 1

- 3.2 SBU
- 4.8 GB

Like I mentioned before, from now on I will not be specifying the general steps in the build process,
only the specific ones.

That means that you should only proceed if you've already extracted the tarball for GCC,and cd'd into
that folder.

Extract the required packages.

```shell
tar -xvf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xvf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xvf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
```

On x86_64 hosts, set the default directory name for 64-bit libraries to "lib".

```shell
case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' \
          -i.orig gcc/config/i386/t-linux64
    ;;
esac
```

The GCC docs recommend creating a build directory.

```shell
mdkir -v build
cd build
```

Prepare for compilation.

```shell
../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.41 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++
```

Compile and install.

```shell
make && make install
```

This build of GCC should have installed some system headers, but not yet at this point.
We need to manually copy them.

```shell
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
```

Check if everything run properly.

```shell
ls $LFS/tools/lib/gcc/x86_64-lfs-linux-gnu/14.2.0/include/limits.h
```

### Linux API Headers

- < 0.1 SBU
- 1.6 GB

Make sure that there are no stale files in the package.

```shell
make mrproper
```

Extract user visible kernel headers form the source.

```shell
make INSTALL_HDR_PATH=dest headers_install
find dest/include -type f ! -name '*.h' -delete
cp -rv dest/include $LFS/usr
```

**Important**: Since we need to use a kernel version 4.x, the current, up-to-date, version of the LFS
uses a kernel version 6.x, which has different steps. I took the step from the LFS 8.0 since that uses
kernel version 4.9.9 and modified it accordingly.

### Glibc

- 1.4 SBU
- 850 MB

Create a symbolic link for LSB compliance. Additionally, create a compatibility link for x86_64.

```shell
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac
```

Some Glibc programs use non-FHS-compliant `/var/db` directory. Patch it.

```shell
patch -Np1 -i ../glibc-2.41-fhs-1.patch
```

The Glibc docs recommend creating a build directory.

```shell
mdkir -v build
cd build
```

Make sure `ldconfig` and `sln` are installed into `/usr/sbin`.

```shell
echo "rootsbindir=/usr/sbin" > configparms
```

Prepare for compilation.

```shell
../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib
```

**Important**: again, due to kernel version, I had to modify this configuration to remove the usage of
kernel 5.4 or above.

Build it and install it.

**Important**: if, for some reason, `$LFS` is not set or if you're running these commands as `root`,
you will install Glibc in your host machine, almost certainly bricking it. You have been warned.

```shell
make
make DESTDIR=$LFS install
```

Fix a hard coded path to the executable loader

```shell
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
```

Now it's a very good time to check everything is working so far.

```shell
echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
# [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
```

If the output is not similar to this one (minding the "x86_64" part for 64 bit hosts),
something has gone wrong.
If it is, clean up and continue.

### Libstdc++

- 0.2 SBU
- 850 MB

This package is part of the GCC tarball, extract it and cd into it. Then, create build directory.

```shell
mdkir -v build
cd build
```

Prepare for compilation.

```shell
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

Remove the libtool archive files, they're harmful for cross-compilation.

```shell
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
```

With this, we have completed our Cross-Toolchain. Now, we will continue building our temporary tools.

## Cross compiling temporary tools

In this step, we will cross-compile basic utilities and install them in their final location.
We will not be able to use them just yet.

### M4

- 0.1 SBU
- 32 MB

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
```

Then compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Ncurses

- 0.4 SBU
- 53 MB

First, we need to build the tic program.

```shell
mkdir build
pushd build
  ../configure AWK=gawk
  make -C include
  make -C progs tic
popd
```

Prepare for compilation.

```shell
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk
```

Compile and install.

```shell
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h
```

### Bash

- 0.2 SBU
- 68 MB

Prepare for compilation.

```shell
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

Make a link for programs that use `sh` for a shell.

```shell
ln -sv bash $LFS/bin/sh
```

### Coreutils

- 0.3 SBU
- 181 MB

Prepare for compilation.

```shell
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

Move programs to their expected final locations.

```shell
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8
```

### Diffutils

- 0.1 SBU
- 35 MB

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### File

- 0.1 SBU
- 42 MB

The `file` command needs to be the same version as the one we are building.
Run this to make a temporary copy of the `file` command.

```shell
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
```

Prepare for compilation.

```shell
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
```

Compile and install.

```shell
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
```

Remove the libtool archive because it's harmful for cross compilation.

```shell
rm -v $LFS/usr/lib/libmagic.la
```

### Findutils

- 0.2 SBU
- 48 MB

Prepare for compilation.

```shell
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Gawk

- 0.1 SBU
- 47 MB

Make sure no unneeded files are installed.

```shell
sed -i 's/extras//' Makefile.in
```

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Grep

- 0.1 SBU
- 27 MB

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Gzip

- 0.1 SBU
- 11 MB

Prepare for compilation.

```shell
./configure --prefix=/usr --host=$LFS_TGT
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Make

- < 0.1 SBU
- 15 MB

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Patch

- 0.1 SBU
- 12 MB

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Sed

- 0.1 SBU
- 21 MB

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Tar

- 0.1 SBU
- 42 MB

Prepare for compilation.

```shell
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

### Xz

- 0.1 SBU
- 21 MB

Prepare for compilation.

```shell
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.4
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

Remove the libtool archive because it's harmful for cross compilation.

```shell
rm -v $LFS/usr/lib/liblzma.la
```

### Binutils - Pass 2

- 0.4 SBU
- 539 MB

To prevent the tools from mistakenly linking libraries from the host, run this command.

```shell
sed '6031s/$add_dir//' -i ltmain.sh
```

Create a separate build directory.

```shell
mdkir -v build
cd build
```

Prepare for compilation.

```shell
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

Remove the libtool archive because it's harmful for cross compilation,
and remove unnecessary static libraries.

```shell
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
```

### GCC - Pass 2

- 4.1 SBU
- 5.5 GB

As before, extract the required packages.

```shell
tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc
```

If building in x86_64, change the default directory name to lib.

```shell
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
```

Override the building rule to allow building libgcc and libstdc++ with POSIX threads support.

```shell
sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in
```

Create a separate build directory.

```shell
mdkir -v build
cd build
```

Prepare for compilation.

```shell
../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
```

Compile and install.

```shell
make
make DESTDIR=$LFS install
```

Create a utility symlink, since a lot of programs run `cc` instead of `gcc`.

```shell
ln -sv gcc $LFS/usr/bin/cc
```

With this, we are ready to enter `chroot` to continue our LFS.

## Chroot and temporary tools

Now that the circular dependencies have been solved,
we can build the tools inside a `chroot` environment,
completely isolated from the host except for the kernel.
To achieve this, we will be creating a "Virtual Kernel File System",
so we can access the only necessary part of our host inside chroot.

**Important**: from now on, the commands must be run as `root`, NOT as `lfs`.
Make sure `$LFS` is set for root.

### Changing ownership

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

### Preparing virtual kernel file systems

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

### Entering chroot

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

### Creating directories

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

### Creating essential files and symlinks

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

### Gettext

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

### Bison

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

### Perl

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

### Python

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

### Texinfo

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

### Util-linux

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

### Cleaning up and saving the temporary system

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

## Building the LFS system

Here we will be constructing the LFS system in earnest.
The installation processes are straightforward.

### Package management

The LFS goes in depth into strategies about package management.
That is out of the scope of this guide, so I'll leave the page for you to read.
[Package Management](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/pkgmgt.html).

Now, let's proceed with the installation of packages.

### Man-pages

- 0.1 SBU
- 52 MB

Remove the man pages for password hashing functions,
`libxcrypt` will provide a better version.

```shell
rm -v man3/crypt*
```

Install the package.

```shell
make -R GIT=false prefix=/usr install
```

### Iana-etc

- < 0.1 SBU
- 4.8 MB

For this package, we just need to copy the files into place.

```shell
cp services protocols /etc
```

### Glibc, for real this time

- 12 SBU
- 3.2 GB

Patch the package.

```shell
patch -Np1 -i ../glibc-2.41-fhs-1.patch
```

The Glibc docs recommend creating a build directory.

```shell
mkdir -v build
cd       build
```

Ensure that the `ldconfig` and `sln` utilities will be installed into `/usr/sbin`.

```shell
echo "rootsbindir=/usr/sbin" > configparms
```

Prepare for compilation.

```shell
../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib
```

Again, due to kernel mismatch, I've adapted the configuration command to remove the kernel limitation.

Compile.

```shell
make
```

Run the tests.

```shell
make check
```

Some will fail:

- io/tst-lchmod
- nss/tst-nss-files-hosts-multi
- nptl/tst-thread-affinity\*

The installation of Glibc will complain about the absence of `/etc/ld.so.conf`,
even if it's harmless.

```shell
touch /etc/ld.so.conf
```

Fix the Makefile to skip an outdated check.

```shell
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
```

Install the package.

```shell
make install
```

Fix a hardcoded path to the executable loaded in the `ldd` script.

```shell
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
```

Install the locales.

```shell
localedef -i C -f UTF-8 C.UTF-8
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f ISO-8859-1 en_GB
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_ES -f ISO-8859-15 es_ES@euro
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i is_IS -f ISO-8859-1 is_IS
localedef -i is_IS -f UTF-8 is_IS.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f ISO-8859-15 it_IT@euro
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i nl_NL@euro -f ISO-8859-15 nl_NL@euro
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i se_NO -f UTF-8 se_NO.UTF-8
localedef -i ta_IN -f UTF-8 ta_IN.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
localedef -i zh_TW -f UTF-8 zh_TW.UTF-8
```

Alternatively, you can install all the locales, but it's unnecessary and time consuming.

```shell
make localedata/install-locales
```

Create and install locales not included in the installation.

```shell
localedef -i C -f UTF-8 C.UTF-8
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true
```

Now we'll configure Glibc.
First, `/etc/nsswitch.conf` since the defaults of Glibc do not work well
in a networked environment.

```shell
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
```

Add time zone data.

```shell
tar -xf ../../tzdata2025a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz
```

Find out your local time.

```shell
tzselect
```

And then create `/etc/localtime`, where `<xxx>` is the selected time zone.

```shell
ln -sfv /usr/share/zoneinfo/<xxx> /etc/localtime
```

Finally, the dynamic loader for libraries.
This will make it search in the right places for the libraries.

```shell
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
```

To add the capability of searching a directory run this command.

```shell
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
```

### Zlib

- < 0.1 SBU
- 6.4 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, check the results and install.

```shell
make
make check
make install
```

Remove a useless static library.

```shell
rm -fv /usr/lib/libz.a
```

### Bzip

- < 0.1 SBU
- 7.2 MB

Apply a patch for the docs.

```shell
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
```

Ensure symlinks are relative.

```shell
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
```

Ensure the man pages are installed in the correct location.

```shell
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
```

Prepare for compilation.

```shell
make -f Makefile-libbz2_so
make clean
```

Compile and install.

```shell
make
make PREFIX=/usr install
```

Install the shared library.

```shell
cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
```

Install the shared `bzip2` library into the `/usr/bin` directory.
Replace two copies of `bzip2` with symlinks.

```shell
cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
```

Remove a useless static library.

```shell
rm -fv /usr/lib/libbz2.a
```

### Xz

- 0.1 SBU
- 21 MB

Prepare for compilation.

```shell
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.6.4
```

Compile, check the results and install.

```shell
make
make check
make install
```

### Lz4

- 0.1 SBU
- 4.2 MB

Compile, check and install.

```shell
make BUILD_STATIC=no PREFIX=/usr
make -j1 check
make BUILD_STATIC=no PREFIX=/usr install
```

### Zstd

- 0.4 SBU
- 85 MB

Compile, check and install.

```shell
make prefix=/usr
make check
make prefix=/usr install
```

Remove the static library.

```shell
rm -v /usr/lib/libzstd.a
```

### File

- < 0.1 SBU
- 19 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, check and install.

```shell
make
make check
make  install
```

### Readline

- < 0.1 SBU
- 16 MB

Fix some renaming issues when installing Readline preventively.

```shell
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
```

Prevent hard coding library search paths in shared libraries.

```shell
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
```

Prepare for compilation.

```shell
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2.13
```

I had an issue where this config command failed.
The root cause was that `/dev` was not mounted correctly, so Zstd installed incorrectly.
Extining chroot, mounting `/dev` and then trying again from Zstd fixed it.

Compile and install.

```shell
make SHLIB_LIBS="-lncursesw"
make install
```

If you want, install the docs.

```shell
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2.13
```

### M4

- 0.3 SBU
- 49 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, check and install.

```shell
make
make check
make install
```

### Bc

- < 0.1 SBU
- 7.8 MB

Prepare for compilation.

```shell
CC=gcc ./configure --prefix=/usr -G -O3 -r
```

Compile, check and install.

```shell
make
make test
make install
```

### Flex

- 0.1 SBU
- 33 MB

Prepare for compilation.

```shell
./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
```

Compile, check and install.

```shell
make
make check
make install
```

Some programs don't know about `flex` just yet, so they will try to use its predecessor `lex`.
To fix this, create a symlink that will run `flex` in `lex` emulation mode.
Also, fix the man page.

```shell
ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1
```

### Tcl

- 3.1 SBU
- 91 MB

Tcl, Expect, and DejaGNU (this one and the next 2 packages) are installed for testing purposes.
It might seem excessive, but it's reassuring, since Binutils, GCC and some other packages are
of vital importance to the system.

Prepare for compilation.

```shell
SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath
```

Build the package.

```shell
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.10|/usr/include|"            \
    -i pkgs/tdbc1.1.10/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
    -e "s|$SRCDIR/pkgs/itcl4.3.2/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.3.2|/usr/include|"            \
    -i pkgs/itcl4.3.2/itclConfig.sh

unset SRCDIR
```

Test and install.

```shell
make test
make install
```

Make the installed library writable so we can remove debugging symbols later.

```shell
chmod -v u+w /usr/lib/libtcl8.6.so
```

Install Tcl's headers since Expect requires them.

```shell
make install-private-headers
```

Create the necessary symlink.

```shell
ln -sfv tclsh8.6 /usr/bin/tclsh
```

Rename a man page that conflicts with a Perl man page.

```shell
mv /usr/share/man/man3/{Thread,Tcl_Thread}.3
```

Optionally install the docs.

```shell
cd ..
tar -xf ../tcl8.6.16-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.16
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.16
```

### Expect

- 0.2 SBU
- 3.9 MB

Expect needs PTYs to work, verify it.

```shell
python3 -c 'from pty import spawn; spawn(["echo", "ok"])'
```

This should output "ok". If it doesn't, go back to "Preparing virtual kernel file systems"
and ensure that all virtual kernel file system are mounted correctly.

Apply a patch.

```shell
patch -Np1 -i ../expect-5.45.4-gcc14-1.patch
```

Prepare for compilation.

```shell
./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
```

Compile, check and install.

```shell
make
make test
make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib
```

### DejaGNU

- < 0.1 SBU
- 6.9 MB

The upstream recommends building DejaGNU on a build directory.

```shell
mkdir -v build
cd       build
```

Prepare for compilation.

```shell
../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi
```

Test the results and install.

```shell
make check
make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3
```

### Pkgconf

- < 0.1 SBU
- 4.7 MB

Prepare for compilation.

```shell
./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.3.0
```

Compile and install.

```shell
make
make install
```

To maintain compatibility with the original Pkg-config, create two symlinks.

```shell
ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
```

### Binutils

- 1.6 SBU
- 819 MB

The Binutils docs recommend creating a build directory.

```shell
mkdir -v build
cd       build
```

Prepare for compilation.

```shell
../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu
```

Compile and test.

```shell
make tooldir=/usr
make -k check
```

For a list of failed tests, run this command.

```shell
grep '^FAIL:' $(find -name '*.log')
```

Install the package.

```shell
make tooldir=/usr install
```

Remove static libraries and other files.

```shell
rm -rfv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a \
        /usr/share/doc/gprofng/
```

### GMP

- 0.3 SBU
- 54 MB

Prepare for compilation.

```shell
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0
```

Compile and generate the HTML docs.

```shell
make
make html
```

Test the results.

```shell
make check 2>&1 | tee gmp-check-log
```

Ensure that at least 199 tests passed.

```shell
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
```

Install the package and the docs.

```shell
make install
make install-html
```

### MPFR

- 0.2 SBU
- 43 MB

Prepare for compilation.

```shell
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1
```

Compile and generate the HTML docs.

```shell
make
make html
```

Test the results.
Ensure that all 198 tests passed.

```shell
make check
```

Install the package and the docs.

```shell
make install
make install-html
```

### MPC

- 0.1 SBU
- 22 MB

Prepare for compilation.

```shell
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1
```

Compile and generate the HTML docs.

```shell
make
make html
```

Test the results.

```shell
make check
```

Install the package and the docs.

```shell
make install
make install-html
```

### Attr

- < 0.1 SBU
- 4.1 MB

Prepare for compilation.

```shell
./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2
```

Compile, test and install.

```shell
make
make check
make install
```

### Acl

- < 0.1 SBU
- 6.5 MB

Prepare for compilation.

```shell
./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2
```

Compile, test and install.
A test name `test/cp.test` is known to fail because Coreutils is not build with Acl support yet.

```shell
make
make check
make install
```

### Libcap

- < 0.1 SBU
- 3.0 MB

Prevent static libraries from being installed.

```shell
sed -i '/install -m.*STA/d' libcap/Makefile
```

Compile the package.

```shell
make prefix=/usr lib=lib
```

Test and install.

```shell
make test
make prefix=/usr lib=lib install
```

### Libxcrypt

- 0.1 SBU
- 12 MB

Prepare for compilation.

```shell
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens
```

Compile, test and install.

```shell
make
make check
make install
```

### Shadow

- 0.1 SBU
- 114 MB

Disable installation of `groups` as Coreutils provides a better alternative.

```shell
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
```

Use Yescrypt instead of the default crypt method since it's more secure.
Also, remove obsolete links.

```shell
sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs
```

Prepare for compilation.

```shell
touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32
```

Compile and install.

```shell
make
make exec_prefix=/usr install
make -C man install-man
```

Let's configure password shadowing.
First, enable it

```shell
pwconv
grpconv
```

The default configuration for useradd needs adjusting.

```shell
mkdir -p /etc/default
useradd -D --gid 999
```

Set the password for root.

```shell
passwd root
```

### GCC

- 46 SBU (with tests)
- 6.3 GB

If building on x86_64, change the directory name of 64-bit libraries to lib.

```shell
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
```

The GCC docs recommend creating a build directory.

```shell
mkdir -v build
cd       build
```

Prepare for compilation.

```shell
../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib
```

Compile.

```shell
make
```

These test are important, but they take an ungodly amount of time.
First-time builders (us) are encouraged to run the test suite.
You can speed up the tests by adding -jX to the make check command,
where X is the number of CPU cores on your system.

Expand the stack size, just in case.

```shell
ulimit -s -H unlimited
```

Remove known test failures.

```shell
sed -e '/cpython/d'               -i ../gcc/testsuite/gcc.dg/plugin/plugin.exp
sed -e 's/no-pic /&-no-pie /'     -i ../gcc/testsuite/gcc.target/i386/pr113689-1.c
sed -e 's/300000/(1|300000)/'     -i ../libgomp/testsuite/libgomp.c-c++-common/pr109062.c
sed -e 's/{ target nonpic } //' \
    -e '/GOTPCREL/d'              -i ../gcc/testsuite/gcc.target/i386/fentryname3.c
```

Test the results as a non-privileged user, without stopping at errors.

```shell
chown -R tester .
su tester -c "PATH=$PATH make -k check"
```

Extract a summary of the results.

```shell
../contrib/test_summary
```

Filter them out by piping through `grep -A7 Summ`.
Check your results against these ones.

- [Build logs](https://www.linuxfromscratch.org/lfs/build-logs/12.3/)
- [Test results](https://gcc.gnu.org/ml/gcc-testresults/)

The tsan tests are known to fail. Some unexpected failures cannot always be avoided.
Unless the tests results are vastly different, it is safe to continue.

Install the package.

```shell
make install
```

The GCC build directory is now owned by tester, change it's ownership to root.

```shell
chown -v -R root:root \
    /usr/lib/gcc/$(gcc -dumpmachine)/14.2.0/include{,-fixed}
```

Create a symlink required by the FHS.

```shell
ln -svr /usr/bin/cpp /usr/lib
```

Many packages use cc to call the C compiler. We already have a symlink,
create a symlink for the man page as well.

```shell
ln -sv gcc.1 /usr/share/man/man1/cc.1
```

Add a compatibility symlink to build programs with Link Time Optimization.

```shell
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
```

Our final toolchain is in place. Perform some sanity checks, just in case.

```shell
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
```

There should be no errors and the output should be similar to this.

```shell
[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
```

Make sure we're set up to use the correct start files.

```shell
grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log
```

The output should be something like this.

```shell
/usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/../../../../lib/Scrt1.o succeeded
/usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/../../../../lib/crti.o succeeded
/usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/../../../../lib/crtn.o succeeded
```

Verify that the compiler is searching for the correct header files.

```shell
grep -B4 '^ /usr/include' dummy.log
```

Again, the output should be something like this.

```shell
#include <...> search starts here:
 /usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/include
 /usr/local/include
 /usr/lib/gcc/x86_64-pc-linux-gnu/14.2.0/include-fixed
 /usr/include
```

Verify that the linker is being used with the correct search paths.

```shell
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
```

It should output something like this.

```shell
SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib64")
SEARCH_DIR("/usr/local/lib64")
SEARCH_DIR("/lib64")
SEARCH_DIR("/usr/lib64")
SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib")
SEARCH_DIR("/usr/local/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("/usr/lib");
```

Make sure we're using the correct libc.

```shell
grep "/lib.*/libc.so.6 " dummy.log
```

Output should be similar to this one.

```shell
attempt to open /usr/lib/libc.so.6 succeeded
```

Make sure GCC is using the correct dynamic linker.

```shell
grep found dummy.log
```

The output should be similar to this one.

```shell
found ld-linux-x86-64.so.2 at /usr/lib/ld-linux-x86-64.so.2
```

If everything is alright, clean up the tests and remove a misplaced file.

```shell
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
```
