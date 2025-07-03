#!/bin/bash

# Ensure user is lfs
if ! whoami | grep -q "lfs"; then
  echo "Please become lfs"
  su - lfs
fi

# Clean up environment
cat >~/.bash_profile <<"EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# Create the configuration for bash
cat >~/.bashrc <<"EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

echo 'Please source the new configuration: "source ~/.bash_profile"'
