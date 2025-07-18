#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

cat >/etc/shells <<"EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF
