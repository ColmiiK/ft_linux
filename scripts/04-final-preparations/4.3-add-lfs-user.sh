#!/bin/bash

# Ensure user is root
if ! whoami | grep -q "root"; then
  echo "ERROR: Please become root before continuing: 'su'"
  exit 1
fi

# Create LFS group
sudo groupadd lfs

# Add LFS user
sudo useradd -s /bin/bash -g lfs -m -k /dev/null lfs

# Set password for LFS user
(echo "1234" echo"1234") | passwd lfs

# Give ownership of tools to LFS
chown -v lfs $LFS/tools

# Give ownership of sources to LFS
chown -v lfs $LFS/sources

# Log in in login shell as LFS
echo "Please log in as user lfs: 'su - lfs'"
