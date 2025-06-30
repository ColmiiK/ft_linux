<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Building the LFS system

Here we will be constructing the LFS system in earnest.
The installation processes are straightforward.

## Package management

The LFS goes in depth into strategies about package management.
That is out of the scope of this guide, so I'll leave the page for you to read.
[Package Management](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/pkgmgt.html).

Now, let's proceed with the installation of packages.

## Man-pages

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

## Iana-etc

- < 0.1 SBU
- 4.8 MB

For this package, we just need to copy the files into place.

```shell
cp services protocols /etc
```

## Glibc, for real this time

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

## Zlib

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

## Bzip

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

## Xz

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

## Lz4

- 0.1 SBU
- 4.2 MB

Compile, check and install.

```shell
make BUILD_STATIC=no PREFIX=/usr
make -j1 check
make BUILD_STATIC=no PREFIX=/usr install
```

## Zstd

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

## File

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

## Readline

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

## M4

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

## Bc

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

## Flex

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

## Tcl

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

## Expect

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

## DejaGNU

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

## Pkgconf

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

## Binutils

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

## GMP

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

## MPFR

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

## MPC

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

## Attr

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

## Acl

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

## Libcap

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

## Libxcrypt

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

## Shadow

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

## GCC

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
