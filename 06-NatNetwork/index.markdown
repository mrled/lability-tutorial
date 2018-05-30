# Chapter 6: NAT network configuration
{:.no_toc}

Build a simple NAT network,
with one NAT gateway server on the public and private networks,
and one NAT'ed server on the private network
that accesses the Internet through the NAT gateway.

## On this page
{:.no_toc}

* TOC
{:toc}

## Setting multiple networks on the NAT gateway

The NAT gateway performs routing and NAT services between the `NATNET-CORP` network and the public network.

### RFC 1918 address ranges

When defining private networks,
you should always follow the best practice of using [RFC 1918](http://www.faqs.org/rfcs/rfc1918.html) IP address ranges.
For IPv4, these ranges are:

- `192.168.0.0/16`
- `172.16.0.0/12`
- `10.0.0.0/8`

Of course, you are free to divide these up into sub networks.
In this chapter, we use only the `10.0.0.0/24` network,
and leave the rest of the `10.0.0.0/8` network undefined.

### Selecting a network range for use on `NATNET-CORP`

The only important concern for selecting which private IP address range to use in any scenario
(including building a lab network in Hyper-V)
is to ensure that it will not need to communicate with any other network that shares the same range.

For almost all cases, this means you should use a different network range than the one on your host's local network.
For instance, if your Hyper-V host is attached to a WiFi network using `192.168.0.0/24`,
then it will have an IP address in the range `192.168.0.0` to `192.168.0.255`.
In this case, you can use any range in `172.16.0.0/12` or `10.0.0.0/8`,
or even another part of the `192.168.0.0/16` range that is not defined on your local network,
like `192.168.1.0/24` or `192.168.44.0/24`.

It's also worth noting that if you wish to connect your lab VMs to an external VPN for some reason,
you will also need to ensure that the network range of the VPN does not overlap with your private network range.

### Double NAT

Your host is almost certainly behind a NAT network already,
which means that any machine on the private `NATNET-CORP` network will be double-NAT'ed.
This makes protocols that rely on dynamic ports,
such as FTP,
hard to use behind the double NAT,
but for a lab this is probably OK.

This is an example network diagram that includes the host's local network using `192.168.0.0/24`.

![network diagram](NetworkDiagram.png)

### Multiple network switches for Lability VMs

You can connect a Lability VM to multiple switches by using a Powershell array for the value of `Lability_SwitchName`.
In our config here, we do so with a snippet in our configuration data like so:

{% highlight powershell %}
@{
    AllNodes = @(
        @{
            NodeName                    = 'NATNET-EDGE1';
            Lability_SwitchName         = @('Wifi-HyperV-VSwitch', 'NATNET-CORP')
        }
    )
}
{% endhighlight %}

For each switch in the array,
as stated previously,
if there is no existing Hyper-V switch with that name,
Lability will look in the `NonNodeData` for a switch configuration
that can set what type of switch it is.
If none is found, Lability will create an Internal Hyper-V switch.

In the configuration data we use for this example (see below),
we define the `NATNET-CORP` network to be an internal Hyper-V network.
This means that it's only accessible to virtual machines which have an adapter on the network;
our host machine has no direct access to the network.

Furthermore, for each switch in the array,
Lability will create a separate virtual network adapter in the node;
one switch results in one network adapter,
two switches in two adapters, etc.
By default, Windows names these adapters `Ethernet`, `Ethernet 2`, `Ethernet 3`, etc.

For more information about Hyper-V switch types,
see [Hyper-V switch types](../backmatter/concepts/hyperv/switch-types)

### Hyper-V network order is not predictable

However, unfortunately _Hyper-V network adapters are not guaranteed to come up in any given order_,
which means that in your configuration file,
the `Wifi-HyperV-VSwitch` network could come up attached to the adapter named `Ethernet`
and the `NATNET-CORP` network could come up attached to the adapter named `Ethernet 2`,
or vice versa, and that _this can change every time you run `Start-Lab`_.
This causes problems,
because it doesn't allow you to assume that either `Ethernet` or `Ethernet 2` is either network in particular
in your configuration document.

We work around this by assigning each adapter a certain MAC address,
then using that MAC address in the configuration document to rename the network adapter after the network
(so that the adapter on the `NATNET-CORP` network is renamed to `NATNET-CORP`),
and then finally using those new adapter names when we assign IP addresses
or do any other network configuration.

That looks like this in our configuration data:

{% highlight powershell %}
@{
    AllNodes = @(
        @{
            NodeName                    = 'NATNET-EDGE1';
            Lability_MACAddress         = @('00-15-5d-cf-01-01', '00-15-5d-cf-01-02')
            Lability_SwitchName         = @('Wifi-HyperV-VSwitch', 'NATNET-CORP')
            InterfaceAlias              = @('Public', 'NATNET-CORP')
        }
    )
}
{% endhighlight %}

And it looks like this in the configuration script:

{% highlight powershell %}
node $AllNodes.Where( {$_.Role -in 'EDGE'}).NodeName {

    xNetAdapterName "RenamePublicAdapter" {
        NewName    = $node.InterfaceAlias[0];
        MacAddress = $node.Lability_MACAddress[0];
    }

    # Do not specify an xIPAddress block to set the IP address for the public adapter;
    # this way, it gets an IP address via DHCP

    xNetAdapterName "RenameCorpnetAdapter" {
        NewName    = $node.InterfaceAlias[1];
        MacAddress = $node.Lability_MACAddress[1];
    }

    xIPAddress 'CorpnetIPAddress' {
        IPAddress      = $node.CorpnetIPAddress;
        InterfaceAlias = $node.InterfaceAlias[1];
        AddressFamily  = $node.AddressFamily;
        DependsOn      = '[xNetAdapterName]RenameCorpnetAdapter';
    }
}
{% endhighlight %}

This technique was found in the Lability examples:

- <https://github.com/VirtualEngine/Lability/blob/dev/Examples/MultipleNetworkExample.ps1>
- <https://github.com/VirtualEngine/Lability/blob/dev/Examples/MultipleNetworkExample.psd1>

and mentioned in a Lability issue as a solution for our problem:

- <https://github.com/VirtualEngine/Lability/issues/176>

### Special considerations when assigning MAC addresses

There are two final items to keep in mind when manually assigning MAC addresses to Hyper-V NICs.

1.  Hyper-V has a dedicated MAC address range of `00-15-5d-00-00-00` thru `00-15-5d-ff-ff-ff`.
    You should make sure your MAC address falls within this range.

2.  Ensure no duplicate MAC addresses exist on your public network.

    When assigning a MAC address to an interface,
    it is important to ensure that it is not a duplicate of any other MAC address on the local network.
    On physical network interfaces,
    this assurance comes from the manufacturer,
    who is assigned a dedicated range of addresses and
    who commits to assigning a unique MAC address to each NIC it sells.
    Microsoft has also been assigned a range for Hyper-V NICs,
    and by default it generates a new NIC in that range for all the virtual NICs owned by each VM.

    However, when we assign MAC addresses ourselves in this chapter,
    it becomes our role to ensure that no NIC on the local network is assigned the same MAC.

## Remoting to machines behind the NAT gateway

We discovered in [Chapter 3](../03-Debugging) that it is possible to use PS Remoting
to connect to a lab VM.
As it turns out,
it is also possible to do this for a lab VM behind a NAT gateway,
but it is a bit trickier.

TODO: finish me

## Lab files

### [ConfigurationData.NATNET.psd1](https://github.com/mrled/lability-tutorial/tree/master/06-NatNetwork/ConfigurationData.NATNET.psd1)

{% highlight powershell %}
{% include_relative ConfigurationData.NATNET.psd1 %}
{% endhighlight %}

### [Configure.NATNET.ps1](https://github.com/mrled/lability-tutorial/tree/master/06-NatNetwork/Configure.NATNET.ps1)

{% highlight powershell %}
{% include_relative Configure.NATNET.ps1 %}
{% endhighlight %}

### [Deploy-NATNET.ps1](https://github.com/mrled/lability-tutorial/tree/master/06-NatNetwork/Deploy-NATNET.ps1)

{% highlight powershell %}
{% include_relative Deploy-NATNET.ps1 %}
{% endhighlight %}
