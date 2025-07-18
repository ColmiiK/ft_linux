#!/bin/bash

# Ensure chroot
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then
  echo "ERROR: Please enter chroot before continuing."
  exit 1
fi

echo "Create a /etc/sysconfig/ifconfig.<xxx> file for your interface"
echo "IFACE should equal the interface name"
echo "IP should be a valid address"
echo "GATEWAY should be the gateway address"
echo "BROADCAST should equal brd"
cat >/etc/sysconfig/ifconfig.eth0 <<"EOF"
ONBOOT=yes
IFACE=eth0
SERVICE=ipv4-static
IP=192.168.1.2
GATEWAY=192.168.1.1
PREFIX=24
BROADCAST=192.168.1.255
EOF

echo "Creating DNS configs..."
cat >/etc/resolv.conf <<"EOF"
# Begin /etc/resolv.conf

nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1

# End /etc/resolv.conf
EOF

echo "Creating hostname config..."
echo "lfs" >/etc/hostname

echo "Creating hosts config..."

cat >/etc/hosts <<"EOF"
# Begin /etc/hosts

127.0.0.1 localhost
127.0.1.1 lfs.local
#<192.168.1.1> <FQDN> <HOSTNAME> [alias1] [alias2 ...]
192.168.1.2 lfs.local lfs
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF
