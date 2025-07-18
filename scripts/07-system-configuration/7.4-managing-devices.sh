#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

ip -o -f inet addr show | awk '$2 == "wlp58s0" { printf "INAME=%s \nIP=%s \nBROADCAST=%s\n", $2, $4, $6 }'

bash /lib/udev/init-net-rules.sh

echo "Ensure 'NAME' is set to the interface name from before"
cat /etc/udev/rules.d/70-persistent-net.rules
