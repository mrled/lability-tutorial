# Chapter 2: A simple configuration
{:.no_toc}

In this chapter, we define and deploy a very simple Lability configuration.

## On this page
{:.no_toc}

* TOC
{:toc}

## Pre-steps

Before deploying this lab,
you must have an existing Hyper-V external switch.

(See [Hyper-V switch types](../backmatter/concepts/hyperv/switch-types)
for more information about Hyper-V's switch types.)

Open the `Hyper-V Manager` application,
click on `Virtual Switch Manager...` in the right pane,
and click the `Create Virtual Switch` button.
Assign a name for the new VSwitch (mine is `WiFi-HyperV-VSwitch`),
attach it to an external network that has Internet access,
and click OK.

You will see my `WiFi-HyperV-VSwitch` switch name in the configuration data below.
If you named your switch something else,
you should change the line in the configuration data to match the name you chose.

## Defining the configuration data

### What is configuration data

Configuration data should be saved in a Powershell data file.
These files end in `.psd1` and contain a Powershell hashtable.
In fact, the syntax is a subset of valid Powershell that can be imported safely -
specifically, dynamic code is not run, but static code is OK.
In practice, this means that you cannot define functions in,
or call them from,
a Powershell data file.
(Powershell configuration data is a bit like how JSON is a subset of valid JavaScript syntax.)

An example, generic data file might look like this:

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

Configuration data files are commonly used in Powershell DSC
(See Microsoft's [Using configuration data in DSC](https://docs.microsoft.com/en-us/powershell/dsc/configdata) for some examples).
DSC configuration data expects two keys:

1. `AllNodes`, which contains information about "nodes" AKA hosts that Powershell DSC will configure
2. `NonNodeData`, which contains other information that is used in the DSC configuration

See [ConfigurationData.SIMPLE.psd1](#configurationdatasimplepsd1) for the example we use in this chapter.

### The `AllNodes` key

In our example, we see just one child of the `AllNodes` key:
A hashtable where `NodeName = 'CLIENT1'`,
indicating configuration specific to a host called `CLIENT1`.

You can see that we specify the VSwitch in this section,
as well as other settings unique to our new VM like what Windows media to install,
how much RAM it has,
and so forth.

### The `NonNodeData` key

We also see one child of the `NonNodeData` key:
the `Lability` key, which contains data that is interpreted specially by Lability.

That key has the `DSCResources` key under it,
which defines any non-default resources (discussed below) that we use in our configuration.
Defining `DSCResources` this way is not required under some conditions,
but it is always recommended.

The `Lability` key,
as well as its `DSCResources` subkey,
is discussed further in Chapter 4.

### Interpretation of configuration data

Powershell DSC uses configuration data like this in DSC _Configuration_ blocks (discussed below).
DSC has a few special keys it knows about,
such as the `PSDscAllowPlainTextPassword` key you can see in our example configuration data.
(This key does what you might expect -
it allows you to pass plaintext creds to the DSC configuration without throwing an error.)

Other keys are not special to DSC, but are special to Lability.
For instance, the `Lability_SwitchName` key determines which Hyper-V switch(es) Lability will attach to its nodes.
If a switch with that name already exists, Lability will use it;
if not, Lability will create an internal Hyper-V switch.
For more information about all the keys that Lability interprets specially,
see the `about_ConfigurationData` help topic.
For more information about defining switches in Lability,
especially if you wish to define a new external switch in your configuration data,
see the `about_Networking` help topic.

Finally, other keys such as `InterfaceAlias` or `AddressFamily` are not treated specially at all,
and must be used in a DSC configuration block.
You can add any number of these keys and assign them any value you like,
but they are not used unless your DSC configuration references them explicitly.
DSC configuration blocks are discussed next.

## Writing a DSC configuration

The DSC configuration is stored in a regular Powershell script ending in `.ps1`.
The configuration will apply DSC _resources_ to the _nodes_ you defined in your configuration data.
A DSC resource is a declaration of what the _desired state_ of the node is.
Let's break that down.

To apply a particular configuration to a node,
it is very common to select the nodes based on the node's `Role`,
which is defined in the configuration data.
For instance, in our [Configure.SIMPLE.ps1](#configuresimpleps1) example configuration that we use in this chapter,
we declare the configuration for our `CLIENT1` node in a block that looks like this:

{% highlight powershell %}
node $AllNodes.Where({$_.Role -in 'CLIENT'}).NodeName {
    ... snip ...
}
{% endhighlight %}

That uses a Powershell expression to only apply to nodes we gave the `CLIENT` role.
If we had defined other nodes in our configuration data that did not have this role,
none of the configuration in that block would apply to them.

Inside of that block we have _resource declarations_,
which declare the desired state for the node.
For instance, at the bottom of our `node` block,
we can see the following:

{% highlight powershell %}
xComputer 'Hostname' {
    Name = $node.NodeName;
}
{% endhighlight %}

This renames the computer using the `xComputer` resource.

## Deploying a Lability DSC configuration

Once the configuration data and configuration itself have been written,
all that remains is to deploy the configuration.
This is simple to do from Powershell.

You can see the [Deploy-SIMPLE.ps1](#deploy-simpleps1) script in its entirety below.
I typically write a short script like this to help me deploy the lab.
However, in this section,
I use commands that accomplish the same thing that can be typed directly into a Powershell prompt.
The script is more repeatable,
but the commands listed below are easier to dissect.

### Build the DSC MOF files:

First, build the DSC MOF files:

{% highlight powershell %}
$configData = ".\ConfigurationData.SIMPLE.psd1"
. Configure.SIMPLE.ps1
& SimpleConfig -ConfigurationData $configData -OutputPath $env:LabilityConfigurationPath -Verbose
{% endhighlight %}

This results in MOF files in the `$env:LabilityConfigurationPath` directory.
(Note that Lability sets that environment variable when you import the module.)
Lability will copy each node's MOF file to the node's VHD,
and start Powershell DSC to apply the configuration in the compiled MOF file when the VM boots.

### Start the lab configuration

Then, start the lab configuration.

Note that the `-Password` argument is used as the local administrator password
for _every_ VM in your lab.

{% highlight powershell %}
$adminPassword = Read-Host -AsSecureString -Prompt "Admin password"
Start-LabConfiguration -ConfigurationData $configData -Verbose -Password $adminPassword
Start-Lab -ConfigurationData $configData -Verbose
{% endhighlight %}

The `Start-LabConfiguration` command does quite a lot:

-   Downloads any Windows trial media to `C:\Lability\ISOs` if they do not already exist there
    (this can take a long time!)
-   Downloads any DSC resources or other necessary for the configuration to `C:\Lability\Resources`
-   Creates virtual hard disk images (VHD or VHDX files) to use as virtual disks for lab VMs
-   Installs Windows to these images offline (without having to start the VMs),
    and saves the results to `C:\Lability\MasterVirtualHardDisks`.
    This means that once you have used a lab VM with a given OS once, for any lab,
    any new lab can use the VM without having to install Windows again.
-   Applies any customizations to copies of these master virtual disks and saves them to `C:\Lability\VMVirtualHardDisks`,
    embedding the Powershell DSC configuration we wrote above
    so that it gets automatically applied when the machine boots.

The first time you run `Start-LabConfiguration` on your lab,
it may take quite some time to download the ISOs and install Windows.
However, after this has been done once, subsequent runs are much faster -
typically this step takes less than a minute on my machine.

Finally, the `Start-Lab` command starts the VMs in Hyper-V.

### `WARNING: A pending reboot is required`

Note that you may want to pass `-IgnorePendingReboot` to `Start-LabConfiguration`.
`Start-LabConfiguration` uses a DSC module behind the scenes called `xPendingReboot`
to determine whether you need to reboot your system before it can deploy.
For issues such as pending Windows Update reboots,
this is pretty important and you should reboot before continuing.
However, it also checks for pending file renames.
These can happen if something has attempted to rename or delete a locked file.
Windows can schedule the rename/delete to happen at next boot,

You can pass `-IgnorePendingReboot` to `Start-LabConfiguration`,
and the `Deploy-SIMPLE.ps1` script accepts an argument of the same name
which it passes to `Start-LabConfiguration` if present.

(See [Pending Reboot](../backmatter/concepts/lability/pending-reboot)
for more information about pending reboot warnings.)

### Wait for the Hyper-V VMs to come up

That said, even when the commands return, there is still some waiting to do.
When the VMs in our lab get started,
Windows needs to come up and do its first boot configuration,
and after that the DSC configuration you wrote is applied automatically as well.

_You cannot log on to a VM using the Hyper-V GUI until the DSC configuration has fully applied successfully._

For a simple case like the one in this example,
the VM might come up just a few minutes after being started.
However, for more complex configurations that involve multiple VMs communicating,
such as creating a domain and joining other VMs to it,
it might take a long time for the DSC configuration to apply completely,
and therefore the VMs might not be available for a long time.

## Logging on to the VMs

Once all of the VMs are showing the logon screen in Hyper-V Manager,
you can simply double click on the VM to get to a logon screen.

Unless your DSC configuration specifically added others,
the only user on your VM will be the default local Administrator account.
Type `Administrator` for the username and use the password you selected earlier to log on.

## Lab exercises and files

1.  Deploy the lab,
    either typing the commands on a Powershell prompt
    or running the `Deploy-SIMPLE.ps1` script.

2.  Wait for the VM to come up
    (to show working Lability and DSC configurations)

3.  Log on to the VM using Hyper-V Manager and Hyper-V Console

4.  Launch a browser and visit a website from the VM
    (to show a working network configuration)

If you get stuck, see [Chapter 3: Debugging](../03-Debugging).

### [ConfigurationData.SIMPLE.psd1](https://github.com/mrled/lability-tutorial/tree/master/02-Simple/ConfigurationData.SIMPLE.psd1)

{% highlight powershell %}
{% include_relative ConfigurationData.SIMPLE.psd1 %}
{% endhighlight %}

### [Configure.SIMPLE.ps1](https://github.com/mrled/lability-tutorial/tree/master/02-Simple/Configure.SIMPLE.ps1)

{% highlight powershell %}
{% include_relative Configure.SIMPLE.ps1 %}
{% endhighlight %}

### [Deploy-SIMPLE.ps1](https://github.com/mrled/lability-tutorial/tree/master/02-Simple/Deploy-SIMPLE.ps1)

{% highlight powershell %}
{% include_relative Deploy-SIMPLE.ps1 %}
{% endhighlight %}
