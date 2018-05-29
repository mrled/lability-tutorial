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
