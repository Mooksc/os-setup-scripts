#!/bin.bash

DEVICE=$(ls /sys/class/net | grep -v lo)

NETWORK_CONFIG=/etc/systemd/network/20-wired.network
RESOLVED_CONFIG=/etc/systemd/resolved.conf

STATIC_IP=$1
SUBNET_MASK=$2
GATEWAY=$3
DNS=$4
DNS_FALLBACK=$5

# set hosts & hostname
echo "arch-vm" > /etc/hostname &&
echo "127.0.0.1 localhost" > /etc/hosts && \
echo "::1 localhost" >> /etc/hosts && \
echo "127.0.1.1 arch-vm.localdomain arch-vm" >> /etc/hosts

# start network device
ip link set $DEVICE up

# start systemd-networkd
systemctl start systemd-networkd.service
systemctl enable systemd-networkd.service

# start systemd-resolved
systemctl start systemd-resolved.service
systemctl enable systemd-resolved.service

# set static IP
ip address add $STATIC_IP$SUBNET_MASK broadcast + dev $DEVICE

# set routing table
ip route add default via $STATIC_IP dev $DEVICE

# network configuration
(echo "[Match]" && echo "Name=$DEVICE" && echo && \
echo "[Network]" && echo "Address=$STATIC_IP$SUBNET_MASK" && \
echo "Gateway=$GATEWAY" && echo "DNS=$DNS") > $NETWORK_CONFIG

# resolved configuration
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
(echo "DNS=$DNS $DNS_FALLBACK" && echo "Domains=-.") >> $RESOLVED_CONFIG
