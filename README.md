# Simple DHCP and authoritative DNS for a home network
An OpenShift cluster requires several DNS entries external to the
cluster. There are many ways to meet this requirement including
cloud services like AWS' Route53. This project establishes a local
authoritative DNS server on a home network. Why go that route? (heh,
pun intended). Well, I have a low cost Inovato Quadra Arm device
running Armbian laying around to use. So, here are the instructions
to configure the Quadra as both a DHCP and DNS authoritative server.

## Configure the server
To begin, copy or clone this repository to your server. Make sure
that the ethernet connection name does not contain any spaces as
this will cause untold issues with the scripts. To do this, list
the available connections using:

    nmcli con show

If the `NAME` field resembles `Wired connection 1` then you'll need
to change it. On my system, I rename it the same as the ethernet
device `eth0`. To do that, use:

    nmcli con mod Wired\ connection\ 1 connection.id eth0

Rerun the command to list the available connections. The output
should now resemble the following:

    NAME  UUID         TYPE      DEVICE
    etho  c6d13973-... ethernet  eth0

### Review the configuration file and scripts
Review all of the parameters in the `demo.conf` file as well as the
scripts. A `/24` network mask is assumed and values are pre-selected
for DNS entries and IPv4 address assignments. Make sure that these
all match your requirements.

### Make sure system is up to date
Run the first script to apply any package updates.

    sudo ./01-setup.sh

Make sure to reboot if there were any kernel updates applied.

### Configure the DNS authoritative server
Before running, make sure that the script configures the forward/reverse
zone files to meet your needs. You can add additional host names
and IPv4 address assignments as needed.

    sudo ./02-config-dns.sh

Make sure that the names and IPv4 addresses in the test script match
your assignments and then verify that the DNS server is working
correctly.

    ./03-test-dns.sh

### Configure the DHCP server
Run the script to configure the DHCP server. Again, assumptions are
made regarding a `/24` network mask, so adjust settings in the
`dhcpd.conf` file configured by the script before running.

    sudo ./04-config-dhcpd.sh

## Adjust your router settings
Finally, adjust your home network router (in my case, I have a
NetGear Orbi attached to my cable modem) to not be your DHCP server.
How to do this is dependent on your router manufacturer and their
configuration tooling so it's not covered here. Restart your router
for the changes to take effect.

## Summary
And that's it. You'll now have a small low cost Arm device acting
as your local DHCP and authoritative DNS server.

