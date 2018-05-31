# Chapter 1: An introduction to Lability

* TOC
{:toc}

## Lability introduction

[Lability](https://github.com/VirtualEngine/Lability) is, according to its repository, a "test lab deployment and configuration module".
It works with Powershell DSC and Hyper-V (and as such requires a Windows lab machine).
With Lability, you can define labs using standard Powershell DSC configuration data and scripts,
and Lability will handle downloading trial ISOs for Windows,
building virtual machines,
copying DSC configuration modules to the VM disk,
and running the DSC scripts when the VMs boot.

This is very powerful.

 -  It allows for very rapid lab creation for studying for certifications or evaluating functionality.
    It's a great tool to have when trying to study for exams like the MCSE.
    It's also very valuable if you wish to evaluate software that you aren't familiar with;
    for instance, at the time of this writing,
    I am using it to prototype a network of SQL Server AlwaysOn Availability Groups for a client at work.

 -  It allows labs to be saved and easily shared.
    You can commit your lab to a git repository and delete the VMs,
    and have high confidence that you can recreate that lab later if necessary.
    You can also easily share labs with coworkers.

## Installing Lability

You can install Lability from PowerShellGet.

If you have never installed modules from the PSGallery before,
you will first have to configure PowerShellGet to trust PSGallery.
(This only needs to be done once per host;
if you've done it before, it's not necessary to repeat.)

{% highlight powershell %}
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
{% endhighlight %}

Once that has been done, you can install Lability:

{% highlight powershell %}
Install-Module -Name Lability
Import-Module -Name Lability
{% endhighlight %}

After installing Lability, you must tell it to configure itself.
You can customize its configuration with `Get-LabHostConfiguration` and `Set-LabHostConfiguration`,
but for most typical users this will not be necessary.
For it to configure itself (whether you customized the configuration or not), you must run:

{% highlight powershell %}
Start-LabHostConfiguration -Verbose
Test-LabHostConfiguration -Verbose
{% endhighlight %}

## Lability documentation

Unfortunately, [the Lability readme](https://github.com/VirtualEngine/Lability/blob/dev/Readme.md) is a bit terse.
However, the module does ship with useful documentation accessible via Powershell.

First, import the Lability module so we can use it

{% highlight powershell %}
<# PS #> Import-Module -Name Lability
{% endhighlight %}

See the list of available commands like this:

{% highlight powershell %}
<# PS #> Get-Command -Module Lability

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Checkpoint-Lab                                     0.14.0     Lability
Function        Clear-LabModuleCache                               0.14.0     Lability
<... snip ...>
{% endhighlight %}

As with all Powershell commands,
get the full help for a given command with a command like this:

{% highlight powershell %}
<# PS #> Get-Help -Name Checkpoint-Lab -Full | more
{% endhighlight %}

Lability also ships with some built-in help files for concepts that aren't captured in the command help.
You can see a list of the files in the dev version [on GitHub](https://github.com/VirtualEngine/Lability/tree/dev/en-US).
At the time of this writing, they are:

    about_Bootstrap
    about_ConfigurationData
    about_CustomResources
    about_Lability
    about_Media
    about_Networking

Finally, you can also [browse the Lability examples on GitHub](https://github.com/VirtualEngine/Lability/tree/dev/Examples).
These examples, along with this tutorial,
can serve as a useful starting point for new test labs.

## Lab exercises

1.  Install Lability

2.  Explore the help topics for Lability commands run in this chapter,
    and at least the `about_Lability` help topic

3.  Read more about the commands for configuring the lab host,
    and understand when you might want to change them

4.  Configure the lab host as discussed above
