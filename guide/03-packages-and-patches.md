<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Packages and patches

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
