#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

##
## install packages
##

dnf -y install dhcp-server

##
## create the DHCP server configuration file
## This assumes a /24 network mask. Adjust accordingly for your
## environment
##

cat > /etc/dhcp/dhcpd.conf <<EOF
option domain-name "$DOMAIN";
default-lease-time 86400;
authoritative;

subnet $SUBNET.0 netmask $NETMASK {
  range $DHCP_MIN $DHCP_MAX;
  option domain-name-servers $HOSTIP;
  option routers $GATEWAY;
  option broadcast-address $BROADCAST;
  max-lease-time 172800;
}

# Add DHCP reservations here using the format:
#
# host server.$DOMAIN {
# 	hardware ethernet 52:54:00:72:2f:6e;
# 	fixed-address $SUBNET.100;
# }
EOF

##
## allow DHCP request through firewall
##

firewall-cmd --permanent --add-service=dhcp
firewall-cmd --reload

##
## fix SELinux settings
##

restorecon -vFr /etc/dhcp

##
## enable the service to start at boot time
##

systemctl enable --now dhcpd

