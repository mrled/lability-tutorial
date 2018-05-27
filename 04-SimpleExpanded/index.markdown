# Chapter 4: Expanding our simple example
{:.no_toc}

WARNING: THIS CHAPTER IS AN INCOMPLETE WORK IN PROGRESS

We expand on the lab built in Chapter 2.

We keep the single VM and the external Hyper-V switch,
and add a discussion of lab prefixes, custom resources, and DSC modules and versions.

## On this page
{:.no_toc}

* TOC
{:toc}

## The external Hyper-V switch

If you haven't followed Chapter 2,
note that the Hyper-V switch you must create at the beginning of that chapter is used here.
I called mine `WiFi-HyperV-VSwitch`;
if you have a different name for the external Hyper-V switch you wish to use,
make sure to replace it in the config data below.

## Lab prefixes

Setting a lab prefix will prefix everything,
including any switches,
so we can't actually do it here.

## Custom resources

We add a custom resource to download the Firefox installer which we can use in our VM.

## DSC modules and versions

TODO: TAKEN FROM CHAPTER 2, EDIT FOR INCLUSION HERE

Defining `DSCResources` is not required if you have installed the resources on your host machine,
but it is recommended because it allows you to specify a specific resource version
rather than simply using whatever is installed locally.
This makes your configurations more portable,
and protects against accidentally installing a new version of the resource that may include breaking changes.

In our `DSCResources` section, we declare that we will use two external resources:

1. [The `xComputerManagement` resource](https://github.com/PowerShell/ComputerManagementDsc),
2. [The `xNetworking` resource](https://github.com/PowerShell/NetworkingDsc)

Both of these resources are published by Microsoft.
However, they are not published with Powershell DSC itself,
and must be installed from the PSGallery.
Fortunately, Lability handles this for us -
by defining the resources here in this way,
we instruct Lability to automatically download the modules from the PSGallery
and install them on our VM's VHD before starting the VM.

One further note:
the `x` prefix is a Microsoft convention indicating an _eXperimental_ resource
which may change its API as new versions are released.
You may also see resources whose names are prefixed with `c`,
which indicates a _Community_ resource.
Resources with no name prefix ship with DSC,
and do not require declaration in the configuration data.

## Lab files

### [ConfigurationData.SIMPLEX.psd1](https://github.com/mrled/lability-tutorial/tree/master/04-SimpleExpanded/ConfigurationData.SIMPLEX.psd1)

{% highlight powershell %}
{% include_relative ConfigurationData.SIMPLEX.psd1 %}
{% endhighlight %}

### [Configure.SIMPLEX.ps1](https://github.com/mrled/lability-tutorial/tree/master/04-SimpleExpanded/Configure.SIMPLEX.ps1)

{% highlight powershell %}
{% include_relative Configure.SIMPLEX.ps1 %}
{% endhighlight %}

### [Deploy-SIMPLEX.ps1](https://github.com/mrled/lability-tutorial/tree/master/04-SimpleExpanded/Deploy-SIMPLEX.ps1)

{% highlight powershell %}
{% include_relative Deploy-SIMPLEX.ps1 %}
{% endhighlight %}
