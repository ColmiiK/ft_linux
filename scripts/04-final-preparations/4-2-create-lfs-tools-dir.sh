#!/bin/bash

# Ensure user is root
if ! whoami | grep -q "root"; then
  echo "Please become root"
  su
fi

# Create directory for tools
mkdir -pv $LFS/tools

# Create symlink on the host system
ln -sv $LFS/tools /
