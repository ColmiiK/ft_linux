#!/bin/bash

# Ensure user is root
if ! whoami | grep -q "root"; then
  echo "ERROR: Please become root: 'su'"
  exit 1
fi

# Create directory for tools
mkdir -pv $LFS/tools

# Create symlink on the host system
ln -sv $LFS/tools /
