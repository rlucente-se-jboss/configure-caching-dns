#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

##
## configure static IPv4 address for this host
## (assumes /24 network mask, so adjust this and other scripts
## accordingly)
##

nmcli con mod $ETHDEV ipv4.addresses $HOSTIP/24
nmcli con mod $ETHDEV ipv4.gateway $GATEWAY
nmcli con mod $ETHDEV ipv4.dns $GATEWAY
nmcli con mod $ETHDEV ipv4.method manual
nmcli con up $ETHDEV

apt -y update
apt -y upgrade
apt -y autoremove

