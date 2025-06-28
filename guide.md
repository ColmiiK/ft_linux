# LFS

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
