---
title: "Proxmox, OVH (SoYouStart), OPNsense, IPv6, Routing"
layout: single
classes: wide
date: 2020-11-08 09:26 +100
toc: true
categories:
  - proxmox
tags:
  - proxmox
  - opnsense
  - ovh
  - soyoustart
  - step-by-step
  - opv6
  - proxmox
---
Having moved my "infrastructure" to a new Proxmox host at Soyoustart / OVH i also wanted to get going with IPv6 again. That did not
seem to be as straight forward as i thought due to the way the OVH network is configured. For IPv4 addresses you can use virtual MAC
addresses to assign the IP addresses to your virtual machines.

Running [OPNsense](https://opnsense.org/) as firewall requires the IPv6 addresses to be routed through the firewall which required some
tweaking and cannot be done with OPNsense alone. I have chosen to run a ndp proxy on the proxmox host for the IPv6 networks (i used /80)
behind the firewall. Based on the [Proxmox forum](https://forum.proxmox.com/threads/opnsense-pfsense-ipv6-and-vips-vips-not-routable-ovh-network.59711/), here is how i did it:

# Install Proxmox #

Install Proxmox as you normally install Proxmox at OVH / Soyoustart. For example via the dashboard.

# Configure Networking (including IPv6) #

Change /etc/network/interfaces from

```terminal
# network interfaces
    auto lo
    iface lo inet loopback

    iface eno1 inet manual

    auto vmbr0
    iface vmbr0 inet dhcp
      bridge-ports eno1
      bridge-stp off
      bridge-fd 0
```

to

```terminal
auto lo
iface lo inet loopback

iface eno1 inet manual
iface eno2 inet manual

auto vmbr0
iface vmbr0 inet static
  address 176.31.122.31/24
  gateway 176.31.122.254
  bridge-ports eno1
  bridge-stp off
  bridge-fd 0
  # Internet

iface vmbr0 inet6 static
  address 2001:41d0:8:411f::1
  netmask 64
  post-up sleep 10
  post-up ip -6 route add 2001:41d0:8:41ff:ff:ff:ff:ff dev vmbr0 || true
  post-up ip -6 route add default via 2001:41d0:8:41ff:ff:ff:ff:ff || true
  post-down ip -6 route del default via 2001:41d0:8:41ff:ff:ff:ff:ff || true
  post-down ip -6 route del 2001:41d0:8:41ff:ff:ff:ff:ff dev vmbr0 || true
  # Internet

auto vmbr2
iface vmbr2 inet manual
  bridge-ports none
  bridge-stp off
  bridge-fd 0
  # INTERNAL
```

Add

```
net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.all.forwarding=1
```

to /etc/sysctl.conf. The forwarding will be needed later and is added now to save some time.

# Install OPNsense #

Install OPNsense as normal with the WAN interface on vmbr0 using a virtual MAC address assigned via the SoYouStart dashboard. I used
vmbr2 as internal network behind the firewall. I installed with the vmbr0 interface only and added the vmbr2 interface later on as LAN
interface after i have added allow rules to access the system via web over the WAN interface.

# OPNsense IPv6 Network Configuration #

Add an IPv6 address for your WAN Interface (I used 2001:41d0:8:411f::2). Then add the Proxmox host IPv6 address (2001:41d0:8:411f::1) as gateway under System -> Gateways -> Single as GW_WAN6. Add GW_WAN6 as a the IPv6 upstream gateway for the static IPv6 configuration for the WAN interface. Remember to add rules to allow
traffic like ICMP if you want to check connectivity.

# IPv6 for your Internal network #

Add a static IPv6 address to your internal network. I used 2001:41d0:8:411f:101::1/80 for that. To be able to access the network from your
proxmox host, add static rules to your /etc/network/interfaces so your IPv6 block looks like:

```
iface vmbr0 inet6 static
  address 2001:41d0:8:411f::1
  netmask 64
  post-up sleep 10
  post-up ip -6 route add 2001:41d0:8:41ff:ff:ff:ff:ff dev vmbr0 || true
  post-up ip -6 route add default via 2001:41d0:8:41ff:ff:ff:ff:ff || true
  post-up ip -6 route add 2001:41d0:8:411f:101::/80 via 2001:41d0:8:411f::2 || true
  post-down ip -6 route del 2001:41d0:8:411f:101::/80 via 2001:41d0:8:411f::2 || true
  post-down ip -6 route del default via 2001:41d0:8:41ff:ff:ff:ff:ff || true
  post-down ip -6 route del 2001:41d0:8:41ff:ff:ff:ff:ff dev vmbr0 || true
  # Internet
```

You should be able to ping 2001:41d0:8:411f:101::1 from your Proxmox host (assuming you added rules to allow ICMP traffic).

# Install and configure ndppd on your Proxmox host #

Install and configure ndppd on your proxmox host:

```
apt install ndppd
```

Create /etc/ndppd.conf:

```
proxy vmbr0 {
  rule 2001:41d0:8:411f:101::/80 {
    static
  }
}
```

Restart ndppd:

```
systemctl restart ndppd
```

# Here we go #

```
root@hurz:~# ping6 -c 5 2001:41d0:8:411f:101::1
PING 2001:41d0:8:411f:101::1(2001:41d0:8:411f:101::1) 56 data bytes
64 bytes from 2001:41d0:8:411f:101::1: icmp_seq=1 ttl=57 time=2.05 ms
64 bytes from 2001:41d0:8:411f:101::1: icmp_seq=2 ttl=57 time=1.99 ms
64 bytes from 2001:41d0:8:411f:101::1: icmp_seq=3 ttl=57 time=2.09 ms
64 bytes from 2001:41d0:8:411f:101::1: icmp_seq=4 ttl=57 time=1.99 ms
64 bytes from 2001:41d0:8:411f:101::1: icmp_seq=5 ttl=57 time=1.95 ms

--- 2001:41d0:8:411f:101::1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 7ms
rtt min/avg/max/mdev = 1.945/2.011/2.085/0.063 ms
root@hurz:~#
```

Let me know if you have any issues in getting it working for you.

