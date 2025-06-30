<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Cross compiling temporary tools

In this step, we will cross-compile basic utilities and install them in their final location.
We will not be able to use them just yet.

## M4

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

## Ncurses

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

## Bash

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

## Coreutils

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

## Diffutils

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

## File

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

## Findutils

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

## Gawk

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

## Grep

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

## Gzip

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

## Make

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

## Patch

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

## Sed

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

## Tar

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

## Xz

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

## Binutils - Pass 2

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

## GCC - Pass 2

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
