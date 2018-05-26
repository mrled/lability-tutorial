# Chapter 2: A simple configuration

* TOC
{:toc}

## Defining the configuration data

Configuration data should be saved in a Powershell data file.
These files end in `.psd1` and contain a Powershell hashtable.
In fact, the syntax is a subset of valid Powershell that can be imported safely -
specifically, dynamic code is not run, but static code is OK.
In practice, this means that you cannot define or call functions from a Powershell data file.
(It is a bit like how JSON is a subset of valid JavaScript syntax.)

An example data file might look like this:

{% highlight powershell %}
@{
    Something = "Else"
    ListOfThings = @(
        "One"
        2
        3.33333333
    )
    PerhapsAHashtable = @{
        Whatever = $True
        Eight = 9
    }
}
{% endhighlight %}

These data files are commonly used in Powershell DSC
(See Microsoft's [Using configuration data in DSC](https://docs.microsoft.com/en-us/powershell/dsc/configdata) for some examples).
DSC configuration data expects two keys:

1. `AllNodes`, which contains information about "nodes" AKA hosts that Powershell DSC will configure
2. `NonNodeData`, which contains other information that is used in the DSC configuration

See [ConfigurationData.SIMPLE.psd1](#configurationdatasimplepsd1) for the example we use in this chapter.
In our example, we see two children of the `AllNodes` key:

1. A hashtable where `NodeName = '*'`, indicating that this is configuration data that applies to all nodes we wish to configure
2. A hashtable where `NodeName = 'CLIENT1'`, indicating configuration specific to a host called `CLIENT1`

Since we are only defining one client,
we could have placed all of the configuration for `NodeName = '*'` in the `NodeName = 'CLIENT1'` hashtable.
This example uses `NodeName = '*'` to show a common pattern we will use later,
which allows you to set configuration values for multiple nodes at once.

### Interpretation of configuration data

In pure Powershell DSC, you create configuration data like this
and then pass it to a DSC "Configuration" stanza (discussed below).
DSC has a few special keys it knows about,
such as the `PSDscAllowPlainTextPassword` key you can see in our example configuration data.
(This key does what you might expect -
it allows you to pass plaintext creds to the DSC configuration without throwing an error.)

Other keys are not special to DSC, but are special to Lability.
For instance, the `Lability_SwitchName` key determines which Hyper-V switch(es) Lability will attach to its nodes.
If a switch with that name already exists, Lability will use it;
if not, Lability will create an internal Hyper-V switch.

For more information about Hyper-V's switch types,
see [Hyper-V: what are the uses for different types of virtual networks?](https://blogs.technet.microsoft.com/jhoward/2008/06/17/hyper-v-what-are-the-uses-for-different-types-of-virtual-networks/)

For more information about all the keys that Lability interprets specially,
see the `about_ConfigurationData` help topic.

Finally, other keys such as `InterfaceAlias` or `AddressFamily` are not treated specially at all,
and must be used in a DSC configuration block.
DSC configuration blocks are discussed next.

## Writing a DSC configuration

The DSC configuration is stored in a regular Powershell script ending in `.ps1`.
The configuration will apply DSC _resources_ to the _nodes_ you defined in your configuration data.

A DSC resource is a declaration of what the _desired state_ of the node is.
For instance, in our [Configure.SIMPLE.ps1](#configuresimpleps1) example configuration that we use in this chapter,
we set the hostname for our example node with the `xComputer` resource, like so:

{% highlight powershell %}
node $AllNodes.Where({$_.Role -in 'CLIENT'}).NodeName {
    xComputer 'Hostname' {
        Name = $node.NodeName;
    }
}
{% endhighlight %}

This fragment applies the `xComputer` resource to all nodes in our configuration data which have a role of `CLIENT`.
The configuration is run for each matching node -
in our configuration data (above), we have defined only one node with the `CLIENT` role.

The `$node` variable will be a hashtable of all the values in our configuration data for the `NodeName = '*'` hashtable,
plus all the values for the `NodeName = 'CLIENT1'` hashtable.
If any key is specified in both hashtables,
the value from the more specific `NodeName = 'CLIENT1'` hashtale overrides the generic value.

## Deploying a Lability DSC configuration

Once the configuration data and configuration itself have been written,
all that remains is to deploy the configuration.
This is simple to do from Powershell.

You can see the [Deploy-SIMPLE.ps1](#deploy-simpleps1) script in its entirety below.
However, I have broken it out here into commands that can be typed directly into Powershell
to make discussing different commands easier here.

### Build the DSC MOF files:

First, build the DSC MOF files:

{% highlight powershell %}
$configData = "$PSScriptRoot\ConfigurationData.SIMPLE.psd1"
. Configure.SIMPLE.ps1
& SimpleConfig -ConfigurationData $configData -OutputPath $env:LabilityConfigurationPath -Verbose
{% endhighlight %}

This results in MOF files in the `$env:LabilityConfigurationPath` directory.
(Note that Lability sets that environment variable when you import the module.)

### Start the lab configuration

Then, start the lab configuration.

Note that the `-Credential` parameter to `Start-LabConfiguration` has some possibly surprising behavior -
that cmdlet ignores the username in that credential,
but sets the local administrator password for _every_ VM in your lab to be the password in the credential.

{% highlight powershell %}
$adminPassword = Read-Host -AsSecureString -Prompt "Admin password"
$adminCred = New-Object -TypeName PSCredential -ArgumentList @("IgnoredUsername", $adminPassword)
Start-LabConfiguration -ConfigurationData $configData -Verbose -Credential $adminCred -IgnorePendingReboot
Start-Lab -ConfigurationData $configData -Verbose
{% endhighlight %}

These commands do quite a lot:

 -  Download any Windows trial media to `C:\Lability\ISOs` if they do not already exist there
    (this can take a long time!)
 -  Download any DSC resources or other necessary for the configuration to `C:\Lability\Resources`
 -  Create virtual hard disk images (VHD or VHDX files) to use as virtual disks for lab VMs
 -  Install Windows to these images offline (without having to start the VMs),
    and save the results to `C:\Lability\MasterVirtualHardDisks`.
    This means that once you have used a lab VM with a given OS once, for any lab,
    any new lab can use the VM without having to install Windows again.
 -  Apply any customizations to copies of these master virtual disks and save them to `C:\Lability\VMVirtualHardDisks`,
    including embedding the Powershell DSC configuration we wrote above
    so that it gets automatically applied when the machine boots.
 -  Creates any Hyper-V switches that are defined in the configuration data but do not exist ahead of time

The first time you run `Start-LabConfiguration` on your lab,
it may take quite some time to download the ISOs and install Windows.
However, after this has been done once, subsequent runs are much faster -
typically this step takes less than a minute on my machine.

### Wait for the Hyper-V VMs to come up

That said, even when the commands return, there is still some waiting to do.

When we started the lab in the previous step, all of the VMs in our lab get started more or less at once.
Windows needs to come up and do its first boot configuration,
and after that the DSC configuration you wrote is applied automatically as well.

For a simple case like the one in this example,
the VM might come up just a few minutes after being started.
However, for more complex configurations that involve multiple VMs communicating,
such as creating a domain and joining other VMs to it,
the VMs might not be available for a very long time.

## Lab files

### [ConfigurationData.SIMPLE.psd1](https://github.com/mrled/lability-tutorial/tree/master/01-Simple/ConfigurationData.SIMPLE.psd1)

{% highlight powershell %}
{% include_relative ConfigurationData.SIMPLE.psd1 %}
{% endhighlight %}

### [Configure.SIMPLE.ps1](https://github.com/mrled/lability-tutorial/tree/master/01-Simple/Configure.SIMPLE.ps1)

{% highlight powershell %}
{% include_relative Configure.SIMPLE.ps1 %}
{% endhighlight %}

### [Deploy-SIMPLE.ps1](https://github.com/mrled/lability-tutorial/tree/master/01-Simple/Deploy-SIMPLE.ps1)

{% highlight powershell %}
{% include_relative Deploy-SIMPLE.ps1 %}
{% endhighlight %}
