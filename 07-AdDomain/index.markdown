# Chapter 7: AD domain
{:.no_toc}

WARNING:
THIS IS AN UNFINISHED CHAPTER, AND THE WINDOWS EVENT FORWARDING STUFF DOES NOT YET WORK.
CURRENTLY, THIS CHAPTER MAY FAIL TO DEPLOY ENTIRELY.

Starting with the network from [Chapter 6](../06-NatNetwork),
add a domain controller.

## On this page
{:.no_toc}

* TOC
{:toc}

## Adding a domain controller

Our domain controller lets us scale the lab more easily.
Now that we have one, we can use it to configure user accounts and assign DHCP leases,
so adding a new machine to the network is very easy.

### Creating AD user accounts

Creating the accounts themselves are very easy.

One potentially surprising behavior in the configuration as we've written it here is that
_it uses the local admin password for the password of the `user1` user also_.
Of course, you could pass in a different password instead,
but for a disposable lab like this one,
using the same password is unlikely to cause any security problems.

Once the account is created, it can be used to log on to any machine in the domain,
and since the `user1` account is a member of both `Domain Admins` and `Enterprise Admins`,
that account will have administrative privileges on all VMs in the domain and over the domain itself.

### Use DHCP for clients, and static IP addresses for servers

You may notice that we wrap the networking configuration in an if statement:

{% highlight powershell %}
node $AllNodes.Where({$_.Role -NotIn 'EDGE'}).NodeName {
    if (-not [System.String]::IsNullOrEmpty($node.IPAddress)) {
        xIPAddress 'PrimaryIPAddress' {
            # ... snip ...
{% endhighlight %}

This lets us apply that `node` block to all machines on the network except the gateway,
but only configure manual networking if a static IP address was defined in the configuration data.
(If networking is not configured manually, Windows will use DHCP to try to obtain a configuration.)

## Windows event forwarding

Now that we have a domain, we can easily enable Windows event forwarding.
This can be very helpful when debugging problems with labs consisting of multiple VMs,
because (assuming the event forwarding configuration gets applied)
you should only need to log on to the VM where the events are being forwarded
in order to see the logs from any other VM.

If you are in the target audience for this tutorial,
you probably know that there are dozens of logging solutions available.
We choose WEF in this chapter because it is agentless and supported out of the box.
In fact, it's supported all the way back to Windows XP SP2 / Server 2003 SP1.

TODO: Finish this section

### Adding event source subscriptions

See the `Query` setting in the `xWEFSubscription` DSC resource in our configuration.
By default, that looks like this:

{% highlight powershell %}
Query = @(
    'Application:*'
    'System:*'
    'Microsoft-Windows-Desired State Configuration-Admin:*'
    'Microsoft-Windows-Desired State Configuration-Operational:*'
)
{% endhighlight %}

These go in to the Windows event subscription XML something like:

{% highlight xml %}
<Select Path="Application">*</Select>
<Select Path="System">*</Select>
<Select Path="Microsoft-Windows-Desired State Configuration-Admin">*</Select>
<Select Path="Microsoft-Windows-Desired State Configuration-Operational">*</Select>
{% endhighlight %}

One thing that may not be obvious is that events can actually be filtered from these sources -
for instance, by replacing the `*` with `*[System[EventId=2]]`,
you can ignore all events with an EventId other than 2.

It may be useful to see examples from other organizations.

-   [Event Forwarding Guidance from NSA](https://github.com/nsacyber/Event-Forwarding-Guidance/tree/master/Subscriptions/samples) -
    a long list of possible subscriptions,
    especially useful for security engineering and analytics.

### Configuring servers to push their events to the collector

TODO: Write this section

### See also

-   [The Windows Event Forwarding Survival Guide](https://hackernoon.com/the-windows-event-forwarding-survival-guide-2010db7a68c4) -
    A quick overview article
-   [Quick and Dirty Large Scale Eventing for Windows](https://blogs.technet.microsoft.com/wincat/2008/08/11/quick-and-dirty-large-scale-eventing-for-windows/) -
    another quick overview
-   [How to set event log security locally or by using Group Policy](https://support.microsoft.com/en-us/help/323076/how-to-set-event-log-security-locally-or-by-using-group-policy) -
    I believe this will help define the registry keys that the group policy objects create for you
    (and we can't use GPO in DSC because there's no way to save GPO objects or import them into a new domain,
    you have to use the GUI).
-   [Windows Event Forwarding to a workgroup collector server](https://blogs.technet.microsoft.com/thedutchguy/2017/01/24/windows-event-forwarding-to-a-workgroup-collector-server/) -
    This shows how to forward Windows events between non-domain-joined servers
-   xWindowsEventForwarding help:
    [ReadMe.Md](https://github.com/PowerShell/xWindowsEventForwarding/blob/dev/ReadMe.md),
    [MSFT_xWEFSubscription.psm1](https://github.com/PowerShell/xWindowsEventForwarding/blob/dev/DSCResources/MSFT_xWEFSubscription/MSFT_xWEFSubscription.psm1)

## Resource ordering

As we have discussed in [Chapter 3](../03-Debugging),
when writing the DSC configuration,
you can minimize confusing errors by paying careful attention to ordering.

This chapter gives us a good place to illustrate this.
Our [Configure.ADLAB.ps1](#configureadlabps1) script has these sections:

TODO: don't forget to update when I add WEF

1.  `node $AllNodes.Where({$true}).NodeName { ... }`:
    LCM setup and ICMP ECHO firewall rules
2.  `node $AllNodes.Where({$_.Role -in 'EDGE'}).NodeName { ... }`:
    Networking for the gateway server
3.  `node $AllNodes.Where({$_.Role -NotIn 'EDGE'}).NodeName { ... }`:
    Networking for all other servers
4.  `node $AllNodes.Where({$_.Role -in 'DC'}).NodeName { ... }`:
    Creating the AD domain on the domain controller
5.  `node $AllNodes.Where({$_.Role -NotIn 'DC'}).NodeName { ... }`:
    Joining all other servers to the AD domain
6.  `node $Allnodes.Where({'Firefox' -in $_.Lability_Resource}).NodeName { ... }`:
    Installing Firefox

Note how the new, complicated functionality of creating and joining the AD domain
is not configured until basic networking is configured.
Keeping networking as early in the configuration as possible,
and certainly before new, untested functionality,
ensures you will be able to log in via PS Remoting
if something were to go wrong with the new functionality in the configuration.

## Lab exercises and files

1.  Add more users via active directory

2.  Change the `CORPNET` Hyper-V switch to "internal" instead of "private".

    Redeploy, then see if you notice any network problems from your host.
    What problems are you seeing? Why are they manifesting?

    (Once finished, delete the `CORPNET` internal Hyper-V switch,
    and any problems you were seeing should dissipate.)

3.  Log on to the domain controller and view Windows events forwarded from the other machines.

4.  Collect more logs, perhaps WinRM logs from
    `Applications and Services Logs\Microsoft\Windows\Windows Remote Management`,
    then redeploy the lab, log on to the domain controller, and view the newly forwarded events.

5.  Advanced/bonus exercise:
    Follow the [Microsoft Advanced Threat Analytics deploy instructions](https://docs.microsoft.com/en-us/advanced-threat-analytics/install-ata-step1)
    to deploy MS ATA to your lab using the GUI.
    MS ATA uses Windows Event Forwarding and is a good real-world use case for this functionality.

    Follow-up bonus:
    automate the installation by adding an ATA Lability resource
    and install ATA using Powershell DSC.

### [ConfigurationData.ADLAB.psd1](https://github.com/mrled/lability-tutorial/tree/master/07-AdDomain/ConfigurationData.ADLAB.psd1)

{% highlight powershell %}
{% include_relative ConfigurationData.ADLAB.psd1 %}
{% endhighlight %}

### [Configure.ADLAB.ps1](https://github.com/mrled/lability-tutorial/tree/master/07-AdDomain/Configure.ADLAB.ps1)

{% highlight powershell %}
{% include_relative Configure.ADLAB.ps1 %}
{% endhighlight %}

### [Deploy-ADLAB.ps1](https://github.com/mrled/lability-tutorial/tree/master/07-AdDomain/Deploy-ADLAB.ps1)

{% highlight powershell %}
{% include_relative Deploy-ADLAB.ps1 %}
{% endhighlight %}
