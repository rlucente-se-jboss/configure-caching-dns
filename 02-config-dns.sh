#!/usr/bin/env bash

. $(dirname $0)/demo.conf

[[ $EUID -ne 0 ]] && exit_on_error "Must run as root"

##
## install packages
##

apt -y install bind9 bind9-utils ufw

##
## set hostname and static IPv4 settings
##

hostnamectl set-hostname ns1.$DOMAIN

##
## create zones file
##

cat > /etc/bind/$DOMAIN.zones <<EOF
//forward zone
zone "$DOMAIN" IN {
	type master;
	file "/etc/bind/$DOMAIN.zone";
};

//backward zone
zone "$REV_SUBNET.in-addr.arpa" IN {
	type master;
	file "/etc/bind/$DOMAIN.rzone";
};
EOF

##
## include our tailored zones file
##

cat > /etc/bind/named.conf.local <<EOF
include "/etc/bind/$DOMAIN.zones";
EOF

##
## create forward zone file
##
## Adjust entries as necessary for your environment. This configuration
## includes a single virtual IP address for a three-node OpenShift
## cluster running on nodes named master0, master1, and master2. I
## also addan NFS server. Again, adjust for your needs.
##

cat > /etc/bind/$DOMAIN.zone <<EOF
\$TTL    86400
@	IN	SOA	ns1.$DOMAIN.	root (
		2022052800 ; serial
        3H         ; refresh (3 hours)
        30M        ; retry (30 minutes)
        2W         ; expiry (2 weeks)
        1W )       ; minimum (1 week)

	IN	NS	ns1.$DOMAIN.

ns1.$DOMAIN.                IN A    $HOSTIP
nfs.$DOMAIN.                IN A    $SUBNET.90

api.$CLUSTER.$DOMAIN.       IN A    $SUBNET.201
api-int.$CLUSTER.$DOMAIN.   IN A    $SUBNET.201
*.apps.$CLUSTER.$DOMAIN.    IN A    $SUBNET.201

master0.$CLUSTER.$DOMAIN    IN A    $SUBNET.80
master1.$CLUSTER.$DOMAIN    IN A    $SUBNET.81
master2.$CLUSTER.$DOMAIN    IN A    $SUBNET.82
EOF

##
## create reverse zone file
##
## Adjust accordingly for your environment per the same comment on
## the forward zone file
##

DNSIP=$(echo $HOSTIP | cut -d. -f4)

cat > /etc/bind/$DOMAIN.rzone <<EOF
\$TTL    86400
@	IN	SOA	ns1.$DOMAIN.	root (
		1997022700 ; serial
		28800      ; refresh
		14400      ; retry
		3600000    ; expire
		86400 )    ; minimum

	IN	NS	ns1.$DOMAIN.

$DNSIP.$REV_SUBNET.in-addr.arpa.    IN  PTR ns1.$DOMAIN.
90.$REV_SUBNET.in-addr.arpa.        IN  PTR nfs.$DOMAIN.

201.$REV_SUBNET.in-addr.arpa.   IN	PTR	api.$CLUSTER.$DOMAIN.
201.$REV_SUBNET.in-addr.arpa.   IN	PTR	api-int.$CLUSTER.$DOMAIN.
80.$REV_SUBNET.in-addr.arpa.    IN  PTR master0.$CLUSTER.$DOMAIN.
81.$REV_SUBNET.in-addr.arpa.    IN  PTR master1.$CLUSTER.$DOMAIN.
82.$REV_SUBNET.in-addr.arpa.    IN  PTR master2.$CLUSTER.$DOMAIN.
EOF

# remove directives for listen-on and allow-query but realize that
# when these are missing, queries are allowed on any interface by
# anyone. Also, set forwarders for domains where this server is not
# authoritative.

sed -Ei '/.+listen-on.+/d' /etc/bind/named.conf.options
sed -Ei '/.+allow-query.+/d' /etc/bind/named.conf.options
grep '^forwarders ' /etc/bind/named.conf.options &> /dev/null || \
    sed -Ei "/^options.+/a forwarders { $FWD_DNS; };" \
        /etc/bind/named.conf.options

##
## secure permissions on zone files
##

chown root:bind /etc/bind/$DOMAIN.zone /etc/bind/$DOMAIN.rzone
chmod 0640 /etc/bind/$DOMAIN.zone /etc/bind/$DOMAIN.rzone

##
## update firewall rules to allow DNS, SSH, and DHCP
##

ufw disable
ufw default deny incoming
ufw allow bootps
ufw allow domain
ufw allow ssh
ufw enable

##
## enable and start the DNS server
##

named-checkzone $DOMAIN /etc/bind/$DOMAIN.zone
named-checkzone $REV_SUBNET.in-addr.arpa /etc/bind/$DOMAIN.rzone

systemctl enable --now named
systemctl status named --no-pager -l

##
## modify static network configuration to point to the DNS server
##

nmcli con mod $ETHDEV ipv4.dns $HOSTIP
nmcli con up $ETHDEV

