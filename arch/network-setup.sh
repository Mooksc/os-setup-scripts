#!/bin.bash

NETWORK_CONFIG=/etc/systemd/network/20-wired.network
RESOLVED_CONFIG=/etc/systemd/resolved.conf
DEVICES=$(ls /sys/class/net | grep -v lo)

echo "the following network devices are available:"
echo $DEVICES
read -p "enter the device to configure: " DEVICE
read -p "desired static IP address: " STATIC_IP
read -p "network subnet mask (ex: /24): " SUBNET_MASK
read -p "network gateway IP address: " GATEWAY
read -p "desired DNS server: " DNS
read -p "DNS fallback server: " DNS_FALLBACK
read -p "hostname: " HOSTNAME

# set hosts & hostname
echo "$HOSTNAME" > /etc/hostname &&
echo "127.0.0.1 localhost" > /etc/hosts && \
echo "::1 localhost" >> /etc/hosts && \
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

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
