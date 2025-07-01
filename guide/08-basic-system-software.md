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

In my case, I had 6 unexpected failures.

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

## Ncurses

- 0.2 SBU
- 46 MB

Prepare for compilation.

```shell
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
```

Compile.

```shell
make
```

Ncurses has a test suite, but can only be run after installation.

The installation of Ncruses will overwrite `libncursesw.so.6.5`, which may crash the shell process.
Install the package with `DESTDIR`, replacing the library file using `install`.

```shell
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /
```

Many applications expect the linker to be able to find non-wide-character Ncurses libraries.
Trick them with symlinks.

```shell
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done
```

Make sure that old applications that look for `-lcurses` are still buildable.

```shell
ln -sfv libncursesw.so /usr/lib/libcurses.so
```

If desired, install the Ncurses docs.

```shell
cp -v -R doc -T /usr/share/doc/ncurses-6.5
```

## Sed

- 0.3 SBU
- 30 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile the package and generate the HTML docs.

```shell
make
make html
```

Test the results.

```shell
chown -R tester .
su tester -c "PATH=$PATH make check"
```

Install the package and the docs.

```shell
make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9
```

## Psmisc

- < 0.1 SBU
- 6.7 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

## Gettext

- 1.7 SBU
- 290 MB

Prepare for compilation.

```shell
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.24
```

Compile, test and install.

```shell
make
make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
```

## Bison

- 2.1 SBU
- 62 MB

Prepare for compilation.

```shell
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
```

Compile, test and install.

```shell
make
make check
make install
```

## Grep

- 0.4 SBU
- 39 MB

Remove a warning about egrep and fgrep.

```shell
sed -i "s/echo/#echo/" src/egrep.sh
```

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

## Bash

- 1.4 SBU
- 53 MB

Prepare for compilation.

```shell
./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-5.2.37
```

Compile.

```shell
make
```

Optionally, run the tests.

```shell
chown -R tester .
su -s /usr/bin/expect tester << "EOF"
set timeout -1
spawn make tests
expect eof
lassign [wait] _ _ _ value
exit $value
EOF
```

Install the package.

```shell
make install
```

Run the newly compiled `bash`, replacing the current one.

```shell
exec /usr/bin/bash --login
```

## Libtool

- 0.6 SBU
- 44 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

Remove useless a static library.

```shell
rm -fv /usr/lib/libltdl.a
```

## GDBM

- < 0.1 SBU
- 13 MB

Prepare for compilation.

```shell
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
```

Compile, test and install.

```shell
make
make check
make install
```

## Gperf

- < 0.1 SBU
- 6.1 MB

Prepare for compilation.

```shell
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
```

Compile, test and install.

```shell
make
make -j1 check
make install
```

We run the tests with only one core as they are known to fail with more.

## Expat

- < 0.1 SBU
- 14 MB

Prepare for compilation.

```shell
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.6.4
```

Compile, test and install.

```shell
make
make check
make install
```

If desired, install the docs.

```shell
install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.4
```

## Inetutils

- 0.2 SBU
- 32 MB

Make the package build with GCC-14.1 or later.

```shell
sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
```

Prepare for compilation.

```shell
./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

```

Compile, test and install.

```shell
make
make check
make install
```

Move the program to the proper location.

```shell
mv -v /usr/{,s}bin/ifconfig
```

## Less

- < 0.1 SBU
- 14 MB

Prepare for compilation.

```shell
./configure --prefix=/usr --sysconfdir=/etc
```

Compile, test and install.

```shell
make
make check
make install
```

## Perl

- 1.3 SBU
- 245 MB

To make sure that Perl uses the libraries already installed in the system instead of building them,
run this pair of commands.

```shell
export BUILD_ZLIB=False
export BUILD_BZIP2=0
```

Prepare for compilation.

```shell
sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.40/core_perl      \
             -D archlib=/usr/lib/perl5/5.40/core_perl      \
             -D sitelib=/usr/lib/perl5/5.40/site_perl      \
             -D sitearch=/usr/lib/perl5/5.40/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads
```

Compile, test and install.

```shell
make
TEST_JOBS=$(nproc) make test_harness
make install
unset BUILD_ZLIB BUILD_BZIP2
```

## XML::Parser

- < 0.1 SBU
- 2.4 MB

Prepare for compilation.

```shell
perl Makefile.PL
```

Compile, test and install.

```shell
make
make test
make install
```

## Intltool

- < 0.1 SBU
- 1.5 MB

Fix a warning caused by perl-5.22 and later.

```shell
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
```

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
```

## Autoconf

- 0.4 SBU (with tests)
- 25 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

## Automake

- 1.1 SBU (with tests)
- 121 MB

Prepare for compilation.

```shell
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17
```

Compile, test and install.
We run the tests with at least 4 logical cores, even on systems with less.
This will speed them up due to internal delays.

```shell
make
make -j$(($(nproc)>4?$(nproc):4)) check
make install
```

## OpenSSL

- 1.8 SBU
- 920 MB

Prepare for compilation.

```shell
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
```

Compile and test.
One test, `30-test_afalg.t` might fail.

```shell
make
HARNESS_JOBS=$(nproc) make test
```

Install the package.

```shell
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
```

Add the version to the docs for consistency.

```shell
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.4.1
```

Optionally, install additional docs.

```shell
cp -vfr doc/* /usr/share/doc/openssl-3.4.1
```

## Libelf from Elfutils

- 0.3 SBU
- 135 MB

Libelf is part of the elfutils-0.192 package.

Prepare for compilation.

```shell
./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy
```

Compile and test.

```shell
make
make check
```

Install only Libelf.

```shell
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
```

## Libffi

- 1.7 SBU
- 11 MB

Prepare for compilation.

```shell
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native
```

Compile, test and install.

```shell
make
make check
make install
```

## Python

- 2.1 SBU
- 501 MB

Prepare for compilation.

```shell
./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations
```

Compile, test and install.
For slow systems, adding a timeout of 1 SBU is recommended,
since some tests can hang.

```shell
make
make test TESTOPTS="--timeout 120"
make install
```

We will be running `pip3` to install Python3 programs in several places in the guide.
This goes against the recommendations of the developers, but since we don't have a
system wide package manager, the recommendations don't really apply.
So, when we run `pip3`, multiple warnings will appear, that is fine.

You can suppress these warnings with a configuration file.

```shell
cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF
```

If desired, install the docs.

```shell
install -v -dm755 /usr/share/doc/python-3.13.2/html

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.13.2/html \
    -xvf ../python-3.13.2-docs-html.tar.bz2
```

## Flit-core

- < 0.1 SBU
- 1.0 MB

Build and install the package.

```shell
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist flit_core
```

## Wheel

- < 0.1 SBU
- 1.6 MB

Build and install the package.

```shell
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist wheel
```

## Setuptools

- < 0.1 SBU
- 26 MB

Build and install the package.

```shell
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist setuptools
```

## Ninja

- 0.2 SBU
- 37 MB

Ninja will always utilize the greatest possible number of processes in parallel.
This can overheat the CPU or make the system run out of memory.
We can limit this, optionally.

```shell
export NINJAJOBS=4
```

And then, make Ninja recognize the environment variable.

```shell
sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
```

Build and install the package.

```shell
python3 configure.py --bootstrap --verbose
install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
```

## Meson

- < 0.1 SBU
- 44 MB

Compile the package.

```shell
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
```

Build and install the package.

```shell
pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson
```

## Kmod

- < 0.1 SBU
- 11 MB

Prepare for compilation.

```shell
mkdir -p build
cd       build

meson setup --prefix=/usr ..    \
            --sbindir=/usr/sbin \
            --buildtype=release \
            -D manpages=false
```

Compile and install the package.

```shell
ninja
ninja install
```

## Coreutils

- 1.2 SBU
- 182 MB

Patch it.

```shell
patch -Np1 -i ../coreutils-9.6-i18n-1.patch
```

Prepare for compilation.

```shell
autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
```

Compile.

```shell
make
```

Optionally, run the tests. First, as root.

```shell
make NON_ROOT_USERNAME=tester check-root
```

Then, as tester.

```shell
groupadd -g 102 dummy -U tester
chown -R tester .
su tester -c "PATH=$PATH make -k RUN_EXPENSIVE_TESTS=yes check" \
   < /dev/null
groupdel dummy
```

Install and move the programs to their specified locations.

```shell
make install
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
```

## Check

- 2.1 SBU (with tests)
- 11 MB

Prepare for compilation.

```shell
./configure --prefix=/usr --disable-static
```

Build, test and install.

```shell
make
make check
make docdir=/usr/share/doc/check-0.15.2 install
```

## Diffutils

- 0.4 SBU
- 50 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Build, test and install.

```shell
make
make check
make install
```

## Gawk

- 0.2 SBU
- 43 MB

Ensure no unneeded files are installed.

```shell
sed -i 's/extras//' Makefile.in
```

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile.

```shell
make
```

Test the results.

```shell
chown -R tester .
su tester -c "PATH=$PATH make check"
```

Install the package.

```shell
rm -f /usr/bin/gawk-5.3.1
make install
```

Create a symlink for the man page.

```shell
ln -sv gawk.1 /usr/share/man/man1/awk.1
```

If desired, install the docs.

```shell
install -vDm644 doc/{awkforai.txt,*.{eps,pdf,jpg}} -t /usr/share/doc/gawk-5.3.1
```

## Findutils

- 0.7 SBU
- 63 MB

Prepare for compilation.

```shell
./configure --prefix=/usr --localstatedir=/var/lib/locate
```

Compile.

```shell
make
```

Test the results.

```shell
chown -R tester .
su tester -c "PATH=$PATH make check"
```

Install the package.

```shell
make install
```

## Groff

- 0.2 SBU
- 108 MB

Prepare for compilation.
`<paper_size>` should be "A4", "letter" or something similar, depending where you live.

```shell
PAGE=<paper_size> ./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

## GRUB

- 0.3 SBU
- 166 MB

Unset any potentially harmful variables.

```shell
unset {C,CPP,CXX,LD}FLAGS
```

Add a missing file from the release tarball.

```shell
echo depends bli part_gpt > grub-core/extra_deps.lst
```

Prepare for compilation.

```shell
./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
```

Compile.

```shell
make
```

The tests are not recommended, since they depend on unavailable packages.

Install the package and move the bash completion support file to the recommended location.

```shell
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
```

## Gzip

- 0.3 SBU
- 21 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

## IPRoute2

- 0.1 SBU
- 17 MB

Remove the man page of a program that will not be installed.

```shell
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8
```

Compile and install.

```shell
make NETNS_RUN_DIR=/run/netns
make SBINDIR=/usr/sbin install
```

If desired, install the docs.

```shell
install -vDm644 COPYING README* -t /usr/share/doc/iproute2-6.13.0
```

## Kbd

- 0.1 SBU
- 34 MB

Patch it.

```shell
patch -Np1 -i ../kbd-2.7.1-backspace-1.patch
```

Remove a redundant program.

```shell
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
```

Prepare for compilation.

```shell
./configure --prefix=/usr --disable-vlock
```

Compile, test and install.

```shell
make
make check
make install
```

If desired, install the docs.

```shell
cp -R -v docs/doc -T /usr/share/doc/kbd-2.7.1
```

## Libpipeline

- 0.1 SBU
- 11 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

## Make

- 0.7 SBU
- 13 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install
```

## Patch

- 0.2 SBU
- 12 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

## Tar

- 0.6 SBU
- 43 MB

Prepare for compilation.

```shell
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35
```

## Texinfo

- 0.3 SBU
- 160 MB

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile, test and install.

```shell
make
make check
make install
```

Optionally install the components belonging in a TeX installation.

```shell
make TEXMF=/usr/share/texmf install-tex
```

If for some reason the `/usr/share/info/dir` needs to be recreated, run this command.

```shell
pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
popd
```

## Vim

- 3.4 SBU
- 251 MB

Change the default location of `vimrc` to `/etc`.

```shell
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
```

Prepare for compilation.

```shell
./configure --prefix=/usr
```

Compile.

```shell
make
```

Ensure that user tester can write to the source tree and exclude tests requiring curl or wget.

```shell
chown -R tester .
sed '/test_plugin_glvs/d' -i src/testdir/Make_all.mak
```

Run the tests.

```shell
su tester -c "TERM=xterm-256color LANG=en_US.UTF-8 make -j1 test" \
   &> vim-test.log
```

Check for the text "ALL DONE" in the log file.

Install the package.

```shell
make install
```

Create a symlink from vi to vim.

```shell
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
```

Add a symlink for the docs for consistency.

```shell
ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.1166
```

Create a default configuration.

```shell
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
```

## MarkupSafe

- < 0.1 SBU
- 500 KB

Compile and install.

```shell
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Markupsafe
```

## Jinja2

- < 0.1 SBU
- 2.5 MB

Compile and install.

```shell
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD
pip3 install --no-index --find-links dist Jinja2
```

## Udev

- 0.3 SBU
- 161 MB

Udev is part of Systemd, extract it.

Remove two unneeded groups from udev rules.

```shell
sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //'               \
    -i rules.d/50-udev-default.rules.in
```

Remove one udev rule requiring a full systemd installation.

```shell
sed -i '/systemd-sysctl/s/^/#/' rules.d/99-systemd.rules.in
```

Adjust hardcoded paths to network config files.

```shell
sed -e '/NETWORK_DIRS/s/systemd/udev/' \
    -i src/libsystemd/sd-network/network-util.h
```

Prepare for compilation.

```shell
mkdir -p build
cd       build

meson setup ..                  \
      --prefix=/usr             \
      --buildtype=release       \
      -D mode=release           \
      -D dev-kvm-mode=0660      \
      -D link-udev-shared=false \
      -D logind=false           \
      -D vconsole=false
```

Get a list of udev helpers as environment variables.

```shell
export udev_helpers=$(grep "'name' :" ../src/udev/meson.build | \
                      awk '{print $3}' | tr -d ",'" | grep -v 'udevadm')
```

Only build the components for udev.

```shell
ninja udevadm systemd-hwdb                                           \
      $(ninja -n | grep -Eo '(src/(lib)?udev|rules.d|hwdb.d)/[^ ]*') \
      $(realpath libudev.so --relative-to .)                         \
      $udev_helpers
```

Install the package.

```shell
install -vm755 -d {/usr/lib,/etc}/udev/{hwdb.d,rules.d,network}
install -vm755 -d /usr/{lib,share}/pkgconfig
install -vm755 udevadm                             /usr/bin/
install -vm755 systemd-hwdb                        /usr/bin/udev-hwdb
ln      -svfn  ../bin/udevadm                      /usr/sbin/udevd
cp      -av    libudev.so{,*[0-9]}                 /usr/lib/
install -vm644 ../src/libudev/libudev.h            /usr/include/
install -vm644 src/libudev/*.pc                    /usr/lib/pkgconfig/
install -vm644 src/udev/*.pc                       /usr/share/pkgconfig/
install -vm644 ../src/udev/udev.conf               /etc/udev/
install -vm644 rules.d/* ../rules.d/README         /usr/lib/udev/rules.d/
install -vm644 $(find ../rules.d/*.rules \
                      -not -name '*power-switch*') /usr/lib/udev/rules.d/
install -vm644 hwdb.d/*  ../hwdb.d/{*.hwdb,README} /usr/lib/udev/hwdb.d/
install -vm755 $udev_helpers                       /usr/lib/udev
install -vm644 ../network/99-default.link          /usr/lib/udev/network
```

Install some custom rules useful in an LFS.

```shell
tar -xvf ../../udev-lfs-20230818.tar.xz
make -f udev-lfs-20230818/Makefile.lfs install
```

Install the man pages.

```shell
tar -xf ../../systemd-man-pages-257.3.tar.xz                            \
    --no-same-owner --strip-components=1                              \
    -C /usr/share/man --wildcards '*/udev*' '*/libudev*'              \
                                  '*/systemd.link.5'                  \
                                  '*/systemd-'{hwdb,udevd.service}.8

sed 's|systemd/network|udev/network|'                                 \
    /usr/share/man/man5/systemd.link.5                                \
  > /usr/share/man/man5/udev.link.5

sed 's/systemd\(\\\?-\)/udev\1/' /usr/share/man/man8/systemd-hwdb.8   \
                               > /usr/share/man/man8/udev-hwdb.8

sed 's|lib.*udevd|sbin/udevd|'                                        \
    /usr/share/man/man8/systemd-udevd.service.8                       \
  > /usr/share/man/man8/udevd.8

rm /usr/share/man/man*/systemd*
```

And unset the udev_helpers variable.

```shell
unset udev_helpers
```

Create the initial configuration database.
This command should be run each time the hardware information is updated.

```shell
udev-hwdb update
```

## Man-DB

- 0.3 SBU
- 44 MB

Prepare for compilation.

```shell
./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.13.0 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap             \
            --with-systemdtmpfilesdir=            \
            --with-systemdsystemunitdir=
```

Compile, test and install.

```shell
make
make check
make install
```

## Procps-ng

- 0.1 SBU
- 28 MB

Prepare for compilation.

```shell
./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.5 \
            --disable-static                        \
            --disable-kill                          \
            --disable-pidwait                       \
            --enable-watch8bit
```

**Important**: since our kernel is older than advised, we have to disable `pidwait`.

Compile, test and install.

```shell
make
chown -R tester .
su tester -c "PATH=$PATH make check"
make install
```

## Util-linux

- 0.5 SBU
- 316 MB

Prepare for compilation.

```shell
./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            --without-systemd     \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.33
```

Some idiot (me) decided to keep going after having to fix the kernel issue,
so now we have to fix this package as well. Downloading and installing version 2.33 works,
after slightly modifying the configuration command, of course.

Compile.

```shell
make
```

Create a dummy `/etc/fstab` file for two tests and run them as non-root.

```shell
touch /etc/fstab
chown -R tester .
su tester -c "make -k check"
```

The hardlink tests may fail.
Also, lsfd and utmp are known to fail in chroot.

Install the package.

```shell
make install
```

## E2fsprogs

- 2.4 SBU
- 99 MB

The E2fsprogs docs recommend a build directory.

```shell
mkdir -v build
cd       build
```

Prepare for compilation.

```shell
../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
```

Compile, test and install.

```shell
make
make check
make install
```

The test named `m_assume_storage_prezeroed` is known to fail.

Remove static libraries.

```shell
rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
```

The package doesn't update the system-wide `dir` file. Unzip then update.

```shell
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
```

If desired, install additional docs.

```shell
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
```

## Sysklogd

- < 0.1 SBU
- 4.1 MB

Prepare for compilation.

```shell
./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --runstatedir=/run \
            --without-logger   \
            --disable-static   \
            --docdir=/usr/share/doc/sysklogd-2.7.0
```

Compile and install.

```shell
make
make install
```

Create a new `/etc/syslog.conf` file by running this command.

```shell
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# Do not open any internet ports.
secure_mode 2

# End /etc/syslog.conf
EOF
```

## SysVinit

- < 0.1 SBU
- 2.9 MB

Patch it.

```shell
patch -Np1 -i ../sysvinit-3.14-consolidated-1.patch
```

Compile and install.

```shell
make
make install
```

## Debugging symbols

Most programs and libraries are built with debugging symbols (-g).
This enlarges the sizes between 50% and 80%, and since it's not usual that
a user debugs their own system software, we can remove them and save space.
Although, this is optional.

As such, I've decided to skip it. The main reason being that since I've changed
some of the packages, this could cause unexpected breakages and brick the system.
Also, I'd like to debug the system if something goes wrong, since this is a
development system that we'll use for the kfs projects.

If you do not wish to skip it, you can follow the procedure in the [LFS](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/stripping.html).

## Cleaning up

Let's clean up some files from tests.

```shell
rm -rf /tmp/{*,.*}
```

There are some unneeded `.la` files we can remove.

```shell
find /usr/lib /usr/libexec -name \*.la -delete
```

The compiler we built before is no longer needed.

```shell
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
```

And finally, remove the `tester` user.

```shell
userdel -r tester
```
