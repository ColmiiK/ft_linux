#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

cat >/etc/profile <<"EOF"
# Begin /etc/profile

export LANG=es_ES.UTF-8

# End /etc/profile
EOF
