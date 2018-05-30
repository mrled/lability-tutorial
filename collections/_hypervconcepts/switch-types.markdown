---
---

# Hyper-V switch types

Hyper-V knows about 3 different types of switches:

1.  External switches

    These are bonded with a network interface on your Hyper-V host,
    and VMs with a virtual network card (NIC) attached to an external switch
    will be directly accessible from your normal network.

    For instance, if your WiFi adapter is called `Ethernet 2`,
    you can create a Hyper-V switch on the `Ethernet 2` adapter,
    and any DHCP server on your WiFi network will assign a new IP address
    to every Hyper-V VM on your `Ethernet 2` Hyper-V switch.

    See this chapter or [Chapter 2](../02-Simple) for use of an external switch.

2.  Internal switches

    These switches create a network between your host and your Hyper-V VM,
    disconnected from any internal network.

    If you create a new internal network,
    Windows will add a new (virtual) NIC to your host OS,
    but it will not be attached to any existing network.

    Internal switches are not used in this tutorial.

3.  Private switches

    These switches are like internal switches,
    but they do _not_ create a new virtual NIC on your host OS.

    They are useful when you want to have a private network among your VMs,
    which your host OS is not a part of.

    See [Chapter 5](../05-SimplePrivateNetwork) for use of a private switch.

You can learn more about Hyper-V switches from
[Hyper-V: what are the uses for different types of virtual networks?](https://blogs.technet.microsoft.com/jhoward/2008/06/17/hyper-v-what-are-the-uses-for-different-types-of-virtual-networks/))