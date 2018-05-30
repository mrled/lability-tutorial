# Chapter 5: Simple private network
{:.no_toc}

Build a simple private network,
with two VMs who can talk to each other,
but cannot talk to the Hyper-V host or the Internet.

## On this page
{:.no_toc}

* TOC
{:toc}

## Defining multiple nodes in configuration data

If you look at the [configuration data for this chapter](#configurationdatasimplenetpsd1),
you will find three entries under `AllNodes` -

1. `NodeName = '*'`
2. `NodeName = 'CLIENT1'`
3. `NodeName = 'CLIENT2'`

The first entry, `NodeName = '*'`, is special -
rather than defining a node named `*`,
it actually sets default values for all nodes.
(Nodes can override these defaults.)
This is a useful way to avoid heavy repetition that might otherwise be unavoidable
when configuring multiple similar nodes.

## The lab network

In the non-node data, we declare a _private_ Hyper-V network, like so:

{% highlight powershell %}
Network = @(
    @{ Name = 'CORP'; Type = 'Private'; }
)
{% endhighlight %}

A private switch allows VMs to communicate only with each other -
not the Internet or even with the host machine.
In this chapter, we will not be connecting the VMs to the Internet,
or even connecting to a host network.
The only way to interact with VMs on a private network is to use the Hyper-V console.

### Declaring switches that already exist

Previously, we have declared the use of a switch which we first created by hand on the Hyper-V host,
such that when it is referenced, that switch already exists.

We can also declare use of switches which do not yet exist on the host.
If that switch is defined in `NonNodeData`,
then the definition laid out in that section is used.
If it isn't, then Lability creates a new internal Hyper-V switch.

### More information on Hyper-V switch types

See [Hyper-V switch types](../backmatter/concepts/hyperv/switch-types)
for more information about different switch types.

## Deploy the lab

Run the [Deploy-SIMPLENET.ps1](#deploy-simplenetps1) script to deploy the lab.

You can connect to the lab via Hyper-V Console,
but you won't be able to use [Powershell Remoting](../backmatter/concepts/powershell/remoting),
because your VMs are on a private network that is not directly connected to your host.
However, you can log on to one machine via the Hyper-V Console,
and use PS Remoting to connect to the other machine in the lab from there.

### Lab exercises

1.  Log in to one of the servers using the Hyper-V management console
    and ping the other server by IP address.

2.  Log in to one of the servers using the Hyper-V management console
    and use `Enter-PSSession` to connect to the other server by IP address.

## Lab files

### [ConfigurationData.SIMPLENET.psd1](https://github.com/mrled/lability-tutorial/tree/master/05-SimpleNetwork/ConfigurationData.SIMPLENET.psd1)

{% highlight powershell %}
{% include_relative ConfigurationData.SIMPLENET.psd1 %}
{% endhighlight %}

### [Configure.SIMPLENET.ps1](https://github.com/mrled/lability-tutorial/tree/master/05-SimpleNetwork/Configure.SIMPLENET.ps1)

{% highlight powershell %}
{% include_relative Configure.SIMPLENET.ps1 %}
{% endhighlight %}

### [Deploy-SIMPLENET.ps1](https://github.com/mrled/lability-tutorial/tree/master/05-SimpleNetwork/Deploy-SIMPLENET.ps1)

{% highlight powershell %}
{% include_relative Deploy-SIMPLENET.ps1 %}
{% endhighlight %}
