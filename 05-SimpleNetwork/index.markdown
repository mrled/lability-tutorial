# Chapter 5: Simple private network
{:.no_toc}

WARNING: INCOMPLETE STUB CHAPTER

Build a simple private network,
with two VMs who can talk to each other,
but cannot talk to the Hyper-V host or the Internet.

-   Add an additional node to the configuration data
-   Explain `NodeName = '*'`
-   Create a private network with no Internet access
-   Explain types of switches and what happens if the switch doesn't already exist

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

## Private networking

In the non-node data, we declare a _private_ Hyper-V network, like so:

{% highlight powershell %}
Network = @(
    @{ Name = 'CORP'; Type = 'Private'; }
)
{% endhighlight %}

See [Hyper-V switch types](../99-Backmatter/Hyper-V-Concepts/switch-types/) for more information about different switch types.

The important thing to keep in mind is that
_private Hyper-V switches allow VMs to communicate only with each other_.
In this chapter, we will not be connecting the VMs to the Internet,
or even connecting to a host network.
The only way to interact with VMs on a private network is to use the Hyper-V console.

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
