# Chapter 4: Expanding our simple example
{:.no_toc}

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

### Hyper-V switch types

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
    disconnected from any intenral network.

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

For more information about using different types of Hyper-V switches in Lability,
see the `about_Networking` help topic.

## Lab prefixes

You can set a lab prefix in the configuration data like so:

{% highlight powershell %}
@{
    NonNodeData = @{
        Lability @{
            EnvironmentPrefix = "PrefixValue-"
        }
    }
}
{% endhighlight %}

This prefix will apply to everything,
including VMs and switches.

Because this chapter uses an already existing external switch
created in [Chapter 2](../02-Simple),
_we do not use a prefix in this chapter_,
because any prefix will apply to our external switch as well.

That is, if we have configuration data like this:

{% highlight powershell %}
@{
    AllNodes = @(
        @{
            NodeName = "ExampleNode"
            Lability_SwitchName = "External-Switch"
        }
    )
    NonNodeData = @{
        Lability @{
            EnvironmentPrefix = "PrefixValue-"
        }
    }
}
{% endhighlight %}

... then our VM will look for an existing switch called `PrefixValue-External-Switch`,
rather than merely `External-Switch`.
This means that if we use a switch created ahead of time with the name `External-Switch`,
we cannpot use the `EnvironmentPrefix` in the `Lability` key for the `NonNodeData` section of our configuration data.

Therefore, in this chapter,
we do not use the `EnvironmentPrefix` key.

## Custom resources

We add a custom resource to download the Firefox installer which we can use in our VM.
This is accomplished via a `Resources` key under the `Lability` key in `NonNodeData`.

In this chapter, we define a custom resource for the Firefox installer.
That resource is specified like this in the configuration data:

{% highlight powershell %}
@{
    AllNodes = @(
        @{
            NodeName = "Example"
            Resources = @('Firefox')
        }
    )
    NonNodeData = @{
        Resources = @(
            Id = 'Firefox';
            Filename = 'Firefox-Latest.exe';
            # This URI redirects to the latest version of the Firefox installer:
            Uri = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US';
        )
    }
}
{% endhighlight %}

And used in our configuration script like this:

{% highlight powershell %}
Script "InstallFirefox" {
    GetScript = { return @{ Result = "" } }
    TestScript = {
        Test-Path -Path "C:\Program Files\Mozilla Firefox"
    }
    SetScript = {
        $process = Start-Process -FilePath "C:\Resources\Firefox-Latest.exe" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "The Firefox installer at exited with code $($process.ExitCode)"
        }
    }
}
{% endhighlight %}

## DSC modules and versions

You can define a `DSCReources` subkey of `NonNodeData`
to declare the names and versions of the DSC resources you wish to use with your nodes.

If this subkey is not defined in your configuration data,
Lability will whatever version of the DSC resource is installed on your Hyper-V host.

That said, it is best practice to define the version in your configuration data,
because doing so allows you to specify a specific resource version
rather than simply using whatever is installed locally.
Lability will automatically download any (specified version of) a module in `DSCReources`,
and save it to `$env:LabilityResourcePath`.
This makes your configurations more portable,
and protects against accidentally installing a new version of the resource that may include breaking changes.

In the `DSCResources` section of this chapter,
we declare that we will use two external resources:

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
