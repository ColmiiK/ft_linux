<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Final preparations

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
