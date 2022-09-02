#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

##
## install packages
##

apt install -y isc-dhcp-server

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
  interface $ETHDEV;
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
# 	fixed-address $SUBNET.201;
# }
EOF

##
## set interfaces for requests
##
sed -i 's/^#\(DHCPDv4_CONF\)/\1/g' /etc/default/isc-dhcp-server
sed -i 's/^\(INTERFACESv4=\)..*/\1"'$ETHDEV'"/g' /etc/default/isc-dhcp-server
sed -i 's/^\(INTERFACESv6=..*\)/\#\1/g' /etc/default/isc-dhcp-server

##
## enable the service to start at boot time
##

systemctl enable --now isc-dhcp-server

