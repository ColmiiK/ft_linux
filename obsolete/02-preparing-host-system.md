<!-- markdownlint-configure-file { "MD013": { "line_length": 300 } } -->

# Preparing the host system

Here we will setting up our host system for the LFS.
That will mean installing packages, creating partitions and checking the hardware.

## Host system requirements

In terms of hardware, the LFS recommends a CPU of at least 4 cores and at least 8 GB of RAM.
Older systems that don't meet these requirements can still build a LFS, they will just take more time.

For the software, the LFS provides a bash script that will check the binaries and aliases needed.
Execute the following command to create and execute said script.

```shell
cat > version-check.sh << "EOF"
#!/bin/bash
# A script to list version numbers of critical development tools

# If you have tools installed in other directories, adjust PATH here AND
# in ~lfs/.bashrc (section 4.4) as well.

LC_ALL=C
PATH=/usr/bin:/bin

bail() { echo "FATAL: $1"; exit 1; }
grep --version > /dev/null 2> /dev/null || bail "grep does not work"
sed '' /dev/null || bail "sed does not work"
sort   /dev/null || bail "sort does not work"

ver_check()
{
   if ! type -p $2 &>/dev/null
   then
     echo "ERROR: Cannot find $2 ($1)"; return 1;
   fi
   v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
   if printf '%s\n' $3 $v | sort --version-sort --check &>/dev/null
   then
     printf "OK:    %-9s %-6s >= $3\n" "$1" "$v"; return 0;
   else
     printf "ERROR: %-9s is TOO OLD ($3 or later required)\n" "$1";
     return 1;
   fi
}

ver_kernel()
{
   kver=$(uname -r | grep -E -o '^[0-9\.]+')
   if printf '%s\n' $1 $kver | sort --version-sort --check &>/dev/null
   then
     printf "OK:    Linux Kernel $kver >= $1\n"; return 0;
   else
     printf "ERROR: Linux Kernel ($kver) is TOO OLD ($1 or later required)\n" "$kver";
     return 1;
   fi
}

# Coreutils first because --version-sort needs Coreutils >= 7.0
ver_check Coreutils      sort     8.1 || bail "Coreutils too old, stop"
ver_check Bash           bash     3.2
ver_check Binutils       ld       2.13.1
ver_check Bison          bison    2.7
ver_check Diffutils      diff     2.8.1
ver_check Findutils      find     4.2.31
ver_check Gawk           gawk     4.0.1
ver_check GCC            gcc      5.2
ver_check "GCC (C++)"    g++      5.2
ver_check Grep           grep     2.5.1a
ver_check Gzip           gzip     1.3.12
ver_check M4             m4       1.4.10
ver_check Make           make     4.0
ver_check Patch          patch    2.5.4
ver_check Perl           perl     5.8.8
ver_check Python         python3  3.4
ver_check Sed            sed      4.1.5
ver_check Tar            tar      1.22
ver_check Texinfo        texi2any 5.0
ver_check Xz             xz       5.0.0
ver_kernel 5.4

if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]
then echo "OK:    Linux Kernel supports UNIX 98 PTY";
else echo "ERROR: Linux Kernel does NOT support UNIX 98 PTY"; fi

alias_check() {
   if $1 --version 2>&1 | grep -qi $2
   then printf "OK:    %-4s is $2\n" "$1";
   else printf "ERROR: %-4s is NOT $2\n" "$1"; fi
}
echo "Aliases:"
alias_check awk GNU
alias_check yacc Bison
alias_check sh Bash

echo "Compiler check:"
if printf "int main(){}" | g++ -x c++ -
then echo "OK:    g++ works";
else echo "ERROR: g++ does NOT work"; fi
rm -f a.out

if [ "$(nproc)" = "" ]; then
   echo "ERROR: nproc is not available or it produces empty output"
else
   echo "OK: nproc reports $(nproc) logical cores are available"
fi
EOF

bash version-check.sh
```

## Partitions

We need at least:

- A boot (/boot) partition
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

The partitions are `/dev/sdbX`, either 1, 2 or 3.

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

In the end, I decided to create a script that will mount all the partitions needed.
This approach seemed to work better for me as we will have to add partitions to our system as we go.
I recommend you do the same.
