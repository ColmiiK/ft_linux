#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

echo "Take the interface name, inet and brd from this output"
ip addr show

bash /lib/udev/init-net-rules.sh

echo "Ensure 'NAME' is set to the interface name from before"
cat /etc/udev/rules.d/70-persistent-net.rules
