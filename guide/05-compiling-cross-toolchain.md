<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Compiling a cross-toolchain

This is a synopsis of the build process:

- Place all sources in a directory accessible from the `chroot` like `$LFS/sources`
- Change to the `$LFS/sources` directory
- For each package:
  - Extract the package with `tar` and only with `tar`
  - Change to the directory created when the package was extracted
  - Follow the instructions for building the package
  - Change back to the sources directory when building is complete
  - Delete the extracted source directory unless instructed otherwise

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

## Binutils - Pass 1

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

## GCC - Pass 1

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

## Linux API Headers

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
kernel version 4.19.325 (the latest 4.x kernel version) and modified it accordingly.

## Glibc

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

## Libstdc++

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
