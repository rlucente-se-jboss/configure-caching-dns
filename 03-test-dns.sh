#!/usr/bin/env bash

. $(dirname $0)/demo.conf

##
## review names and addresses to make sure that they match the
## entries in your forward and reverse zone file created in the
## 02-config-dns.sh script
##

for name in ns1 nfs api.$CLUSTER api-int.$CLUSTER fake.apps.$CLUSTER \
    master0.$CLUSTER master1.$CLUSTER master2.$CLUSTER redhat.com

do
    HOSTNAME=$name.$DOMAIN
    dig @$HOSTIP $HOSTNAME || exit_on_error "Cannot resolve $HOSTNAME"
done | grep IN | grep -vE '^;|SOA'

for addr in $HOSTIP $SUBNET.201 $SUBNET.80 $SUBNET.81 $SUBNET.82 $SUBNET.90
do
    dig @$HOSTIP -x $addr || exit_on_error "Cannot resolve $addr"
done | grep IN | grep -vE '^;|SOA'

