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
$> bash version-check.sh
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
$> fdisk <disk route>
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
root@vbox:~# lsblk
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
$> mkfs -v -t ext4 <boot partition>
$> mkswap <swap partition>
$> mkfs -v -t ext4 <root partition>
```

In my case, the partitions are `/dev/sdbX`, either 1, 2 or 3.

Before we continue, make sure that your `LFS` environment variable is set properly FOR THE ROOT USER.

```shell
$> echo $LFS
/mnt/lfs
```

To achieve this, add it in the `/etc/environment` file.

Also, set the `umask` for the system to `022`. This will ensure that the files are created with
proper permissions.

```shell
$> umask 022
```

Let's mount the partitions. First, create a mount point, then mount them.

```shell
$> mkdir -p $LFS
$> mount -v -t ext4 <root partition> $LFS
$> mkdir -p $LFS/boot
$> mount -v -t ext4 <boot partition> $LFS/boot
$> swapon -v <swap partition>
```

Set the ownership of the `$LFS` directory to root and the file permissions.

```shell
$> chown root:root $LFS
$> chmod 755 $LFS
```

And we're set to start installing packages.

## Packages

Before we start downloading tarballs, we need a place to store and work with them.

```shell
$> mkdir -v $LFS/sources
mkdir: created directory '/mnt/lfs/sources'
```

Modify the permissions to make it writable and sticky, meaning that only the owner can delete files inside it.

```shell
$> chmod -v a+wt $LFS/sources
mode of '/mnt/lfs/sources' changed from 0755 (rwxr-xr-x) to 1777 (rwxrwxrwt)
```

Now we can start downloading packages. You could download each tarball individually (not very programmer of you)
or you could use a `wget-list-sysv` file like the one provided in the LFS book. It has all of the packages
required by the subject, so convenient. You can get it right [here](https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv).

```shell
$> curl https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv > wget-list-sysv
```

Download all the packages before proceeding, it's going to take a little while.
The total download size should be around 500MB.

```shell
$> wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
```

LFS also provides us with a `md5sums` file to check the authenticity of everything we just downloaded.

```shell
$> curl https://www.linuxfromscratch.org/lfs/view/stable/md5sums > $LFS/sources/md5sums
$> pushd $LFS/sources
$>  md5sum -c md5sums
$> popd
```

Also, make sure that the owner of these files is root. If they aren't, fix it.

```shell
$> chown root:root $LFS/sources/*
```

**Important note**: in our subject, we are required to use a kernel version 4.x.
The kernel used in LFS is the latest one, which is no good for us. Delete that kernel version and
get the tarball for a 4.x kernel.

```shell
$> rm $LFS/sources/linux-6.13.4.tar.xz
$> wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.9.tar.gz
```

I also had to manually download a different `expat` version than the provided one.
Mileage may vary.

```shell
$> wget https://prdownloads.sourceforge.net/expat/expat-2.7.1.tar.xz
```

We now have all the packages ready for our very own Linux.

## Final preparations

We will start by populating the LFS file system.

```shell
$> mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
mkdir: created directory '/mnt/lfs/etc'
mkdir: created directory '/mnt/lfs/var'
mkdir: created directory '/mnt/lfs/usr'
mkdir: created directory '/mnt/lfs/usr/bin'
mkdir: created directory '/mnt/lfs/usr/lib'
mkdir: created directory '/mnt/lfs/usr/sbin'
$> for i in bin lib sbin; do
    ln -sv usr/$i $LFS/$i
   done
'/mnt/lfs/bin' -> 'usr/bin'
'/mnt/lfs/lib' -> 'usr/lib'
'/mnt/lfs/sbin' -> 'usr/sbin'
$> case $(uname -m) in
    x86_64) mkdir -pv $LFS/lib64 ;;
   esac
mkdir: created directory '/mnt/lfs/lib64'
```

The programs we will compile later need to be compiled with a cross-compiler, we will install this tool in a
special directory.

```shell
$> mkdir -pv $LFS/tools
mkdir: created directory '/mnt/lfs/tools'
```

To prevent us from bricking the system, the packages we will be building next will be done with an
unprivileged user. Create one if needed. To simplify things, we will create a `lfs` user that
belongs to a `lfs` group.

```shell
$> groupadd lfs
$> useradd -s /bin/bash -g lfs -m -k /dev/null lfs
```

You can set a password for the user if you want, so you don't need to be root to change to it.

```shell
$> passwd lfs
New password:
Retype new password:
passwd: password updated successfully
```

Now we will give the `lfs` user full access and ownership of the files under `$LFS`.

```shell
$> chown -v lfs $LFS/{usr{,/*},var,etc,tools}
changed ownership of '/mnt/lfs/usr' from root to lfs
changed ownership of '/mnt/lfs/usr/bin' from root to lfs
changed ownership of '/mnt/lfs/usr/lib' from root to lfs
changed ownership of '/mnt/lfs/usr/sbin' from root to lfs
changed ownership of '/mnt/lfs/var' from root to lfs
changed ownership of '/mnt/lfs/etc' from root to lfs
changed ownership of '/mnt/lfs/tools' from root to lfs
$> case $(uname -m) in
    x86_64) chown -v lfs $LFS/lib64 ;;
   esac
changed ownership of '/mnt/lfs/lib64' from root to lfs
```

Log in as the `lfs` user with a login shell. The purpose of this is to have a clean slate to create
our working environment, without potentially hazardous environment variables from the host.

```shell
$> su - lfs
```

Let's set a working environment.

```shell
$> cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
```

Since a login shell only reads the `.bash_profile` file, with this we create a non-login shell with only the
`HOME`, `TERM` and `PS1` variables set. In this new non-login shell, we can specify a `.bashrc` to set
the new variables we do want.

```shell
$> cat > ~/.bashrc << "EOF"
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
$> cat >> ~/.bashrc << "EOF"
export MAKEFLAGS=-j$(nproc)
EOF
```

To ensure the environment is set, force the shell to read the new user profile.

```shell
$> source ~/.bash_profile
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
$> echo $LFS
/mnt/lfs
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

### Binutils - Pass 1

- 1 SBU
- 677 MB

I'll describe the building process for this first package in depth, with the next ones I'll skip the
repeated instructions, such as unpacking.

```shell
$> cd $LFS/sources
$> tar -xvf binutils-2.44.tar.xz
$> cd binutils-2.44
```

The Binutils docs recommend creating a specific build directory.

```shell
$> mdkir -v build
mkdir: created directory 'build'
$> cd build
```

Now, prepare Binutils for compilation. To check for SBU, wrap the commands in `time`.

```shell
$> time { ../configure --prefix=$LFS/tools \
                --with-sysroot=$LFS \
                --target=$LFS_TGT \
                --disable-nls \
                --enable-gprofng=no \
                --disable-werror \
                --enable-new-dtags \
                --enable-default-hash-style=gnu && \
  make && make install; }
```

For reference, in my machine (8 cores, 8 GB of RAM) this took:

```shell
real    0m53.897s
user    2m27.555s
sys     0m52.519s
```

Finally, we delete the extracted directory and move on with the next tool.

```shell
$> cd ../..
$> rm -rf binutils-2.44
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
$> tar -xvf ../mpfr-4.2.1.tar.xz
$> mv -v mpfr-4.2.1 mpfr
$> tar -xvf ../gmp-6.3.0.tar.xz
$> mv -v gmp-6.3.0 gmp
$> tar -xvf ../mpc-1.3.1.tar.gz
$> mv -v mpc-1.3.1 mpc
```

On x86_64 hosts, set the default directory name for 64-bit libraries to "lib".

```shell
$> case $(uname -m) in
    x86_64)
      sed -e '/m64=/s/lib64/lib/' \
          -i.orig gcc/config/i386/t-linux64
    ;;
esac
```

The GCC docs recommend creating a build directory.

```shell
$> mdkir -v build
mkdir: created directory 'build'
$> cd build
```

Prepare for compilation.

```shell
$> ../configure               \
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
$> make && make install
```

This build of GCC should have installed some system headers, but not yet at this point.
We need to manually copy them.

```shell
$> cd ..
$> cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
```

Check if everything run properly.

```shell
$> ls $LFS/tools/lib/gcc/x86_64-lfs-linux-gnu/14.2.0/include/limits.h
```

### Linux API Headers

- < 0.1 SBU
- 1.6 GB

Make sure that there are no stale files in the package.

```shell
$> make mrproper
```

Extract user visible kernel headers form the source.

```shell
$> make INSTALL_HDR_PATH=dest headers_install
$> find dest/include -type f ! -name '*.h' -delete
$> cp -rv dest/include $LFS/usr
```

**Important**: Since we need to use a kernel version 4.x, the current, up-to-date, version of the LFS
uses a kernel version 6.x, which has different steps. I took the step from the LFS 8.0 since that uses
kernel version 4.9.9 and modified it accordingly.

### Glibc

- 1.4 SBU
- 850 MB

Create a symbolic link for LSB compliance. Additionally, create a compatibility link for x86_64.

```shell
$> case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac
```

Some Glibc programs use non-FHS-compliant `/var/db` directory. Patch it.

```shell
$> patch -Np1 -i ../glibc-2.41-fhs-1.patch
```

The Glibc docs recommend creating a build directory.

```shell
$> mdkir -v build
mkdir: created directory 'build'
$> cd build
```

Make sure `ldconfig` and `sln` are installed into `/usr/sbin`.

```shell
$> echo "rootsbindir=/usr/sbin" > configparms
```

Prepare for compilation.

```shell
$> ../configure                          \
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
$> make
$> make DESTDIR=$LFS install
```

Fix a hard coded path to the executable loader

```shell
$> sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd
```

Now it's a very good time to check everything is working so far.

```shell
$> echo 'int main(){}' | $LFS_TGT-gcc -xc -
$> readelf -l a.out | grep ld-linux
[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
```

If the output is not similar to this one (minding the "x86_64" part for 64 bit hosts),
something has gone wrong.
If it is, clean up and continue.

### Libstdc++

- 0.2 SBU
- 850 MB

This package is part of the GCC tarball, extract it and cd into it. Then, create build directory.

```shell
$> mdkir -v build
mkdir: created directory 'build'
$> cd build
```

Prepare for compilation.

```shell
$> ../libstdc++-v3/configure        \
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
$> make
$> make DESTDIR=$LFS install
```

Remove the libtool archive files, they're harmful for cross-compilation.

```shell
$> rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la
removed '/mnt/lfs/usr/lib/libstdc++.la'
removed '/mnt/lfs/usr/lib/libstdc++exp.la'
removed '/mnt/lfs/usr/lib/libstdc++fs.la'
removed '/mnt/lfs/usr/lib/libsupc++.la'
```

With this, we have completed our Cross-Toolchain. Now, we will continue building our temporary tools.

## Cross compiling temporary tools
