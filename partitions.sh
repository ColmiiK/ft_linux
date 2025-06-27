#!/bin/bash
set -e

IMG="$HOME/lfs.img"
SIZE=30000     # size in MB
BOOT_SIZE=512  # MB
SWAP_SIZE=2048 # MB

echo "Creating $SIZE MB image at $IMG..."
dd if=/dev/zero of="$IMG" bs=1M count=$SIZE status=progress

echo "Creating partitions..."

# Use parted for scripting partitioning (more reliable for images)
parted "$IMG" --script mklabel gpt

# /boot partition
parted "$IMG" --script mkpart primary ext4 1MiB ${BOOT_SIZE}MiB

# swap partition
parted "$IMG" --script mkpart primary linux-swap ${BOOT_SIZE}MiB $((BOOT_SIZE + SWAP_SIZE))MiB

# root partition
parted "$IMG" --script mkpart primary ext4 $((BOOT_SIZE + SWAP_SIZE))MiB 100%

echo "Setting up loop device..."
LOOPDEV=$(sudo losetup --find --show -P "$IMG")
echo "Loop device is $LOOPDEV"

echo "Formatting partitions..."

sudo mkfs.ext4 "${LOOPDEV}p1"
sudo mkswap "${LOOPDEV}p2"
sudo mkfs.ext4 "${LOOPDEV}p3"

echo "Mounting partitions..."

sudo mkdir -p /mnt/lfs
sudo mount "${LOOPDEV}p3" /mnt/lfs

sudo mkdir -p /mnt/lfs/boot
sudo mount "${LOOPDEV}p1" /mnt/lfs/boot

sudo swapon "${LOOPDEV}p2"

echo "LFS environment ready!"
echo "Root mounted on /mnt/lfs"
echo "/boot mounted on /mnt/lfs/boot"
echo "Swap enabled on ${LOOPDEV}p2"

# Optional: print current mount and swap info
lsblk -o NAME,SIZE,MOUNTPOINT,TYPE
swapon --show
