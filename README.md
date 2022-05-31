# Simple DHCP and authoritative DNS for a home network
An OpenShift cluster requires several DNS entries external to the
cluster. There are many ways to meet this requirement include cloud
services like AWS' Route53. This project establishes a local
authoritative DNS server on a home network. Why go that route? (heh,
pun intended). Well, I have a Raspberry Pi 4 laying around and,
with the newer 5.x kernel in Red Hat Enterprise Linux 9, this was
trivial to do. So, here are the instructions to install RHEL 9 on
a small Raspberry Pi 4 and have it serve as both a DHCP and DNS
authoritative server.

## Install RHEL on the Pi
My colleague Paul Armstrong outlines the [required
steps](https://github.com/parmstro/94Pi4/wiki/Manual-Deployment-Method). In
a nutshell, you'll make sure that the RPi 4 has the latest bootloader
firmware, then you'll format a small FAT32 partition on the SD-card
for the [upstream RPi 4 UEFI firwmare](https://github.com/pftf/RPi4/releases),
and then finally you'll perform a standard installation of RHEL 9
from USB. Paul does an excellent job explaining these steps.

For this project, you can start with a `minimal` RHEL installation
and DHCP for the IP configuration. These instructions focus on
non-routable IPv4 addresses, so you can ignore IPv6 configuration
when going through the operating system installation.

## Configure the server
Once you have RHEL installed, remove the USB media and reboot the
system. You're now ready to configure the various services.

To begin, copy or clone this repository to your server.

### Review the configuration file and scripts
Make sure to change the `USERNAME` and `PASSWORD` parameters in the
`demo.conf` file. I strongly recommend reviewing all of the remaining
parameters in that file as well as the scripts. A `/24` network
mask is assumed and values are pre-selected for DNS entries and
IPv4 address assignments. Make sure that these all match your
requirements.

### Register for updates and insights
Run the first script to register the system with the Red Hat
Subscription Manager and Insights. This will also apply any package
updates.

    sudo ./01-setup-rhel.sh

Make sure to reboot if there were any kernel updates applied.

### Configure the DNS authoritative server
Before running, make sure that the script configures the forward/reverse
zone files to meet your needs. You can add additional host names
an IPv4 address assignments as needed.

    sudo ./02-config-dns.sh

Make sure that the names and IPv4 addresses in the test script match
your assignements and then verify that the DNS server is working
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
And that's it. You'll now have a small RPi4 running RHEL 9 and
acting as your local DHCP and authoritative DNS server.

