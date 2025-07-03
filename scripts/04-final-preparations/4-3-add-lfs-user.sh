#!/bin/bash

# Ensure user is root
if ! whoami | grep -q "root"; then
  echo "Please become root"
  su
fi

# Create LFS group
groupadd lfs

# Add LFS user
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

# Set password for LFS user
passwd lfs

# Give ownership of tools to LFS
chown -v lfs $LFS/tools

# Give ownership of sources to LFS
chown -v lfs $LFS/sources

# Log in in login shell as LFS
su - lfs
