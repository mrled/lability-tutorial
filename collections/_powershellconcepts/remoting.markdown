---
---

# Powershell Remoting
{:.no_toc}

Build a simple private network,
with two VMs who can talk to each other,
but cannot talk to the Hyper-V host or the Internet.

Powershell has built-in remoting, based on WinRM, and called Powershell Remoting.

## On this page
{:.no_toc}

* TOC
{:toc}

## Scope

Windows Remoting (or WinRM), which underpins Powershell Remoting, is a large topic.
This document is not a general primer on Windows Remoting,
but only discusses Powershell remoting scenarios that are a good fit for Lability labs.
To that end, our scope is:

1.  Remoting that works out of the box.

    Actually, WinRM is not enabled at all on a default Windows install.
    However, Lability uses its bootstrap process to enable the PS Remoting server for all media it knows about.
    It also configures the firewall to allow access.
    For more information about this, see the `about_Bootstrap` help topic.

2.  Remoting that works on older OSes

    SSH remoting is much simpler,
    but this has not shipped with any version of Windows except the very latest Windows 10 release,
    and anyway, Lability doesn't enable it by default even on that OS.

3.  Remoting that works for machines that are not joined to the same domain,
    or any domain at all

    This limits us to using CredSSP rather than Kerberos credential passing.
    In production, this is not particularly secure,
    but for the threat model of a lab environment this does not adversely affect security posture.

## Interactivity

You can use remoting interactively or not,
but each way has different restrictions.

### Interactive use

For interactive use, you will use `Enter-PSSession`,
which will change your prompt and run every command you type on the remote machine, like this:

{% highlight powershell %}
<# PS@host #> Enter-PSSession -ComputerName test01.example.com
<# PS@test01 #> Write-Output "Hello from $env:ComputerName"
Hello from test01
<# PS@test01 #>    # you can run other commands on the test01 server here
<# PS@test01 #> exit
<# PS@host #>
{% endhighlight %}

When connecting interactively,
it is not possible to reference variables from your host.

{% highlight powershell %}
<# PS@host #> $test = "TEST"
<# PS@host #> Write-Output "Value of test is '$test'"
Value of test is 'TEST'
<# PS@host #> Enter-PSSession -ComputerName test01.example.com
<# PS@test01 #> Write-Output "Value of test is '$test'"
Value of test is ''
{% endhighlight %}

### Non-interactive use

For non-interactive use, you will use `Invoke-Command` with the `-ComputerName` argument.
This will connect to the remote server, run your command, and then return back to your host.
That might look like this:

{% highlight powershell %}
<# PS@host #> Invoke-Command -ComputerName test01.example.com -ScriptBlock { Write-Output "Hello from $env:ComputerName" }
Hello from test01
<# PS@host #>
{% endhighlight %}

WHen we use PS Remoting non-interactively,
we can reference variables from the host with a special prefix:

{% highlight powershell %}
<# PS@host #> $test = "TEST"
<# PS@host #> Invoke-Command -ComputerName test01.example.com -ScriptBlock { Write-Output "Value of test is '$using:test'" }
Value of test is 'TEST'
<# PS@host #>
{% endhighlight %}

Note that we referenced the `$test` variable as `$using:test` in our scriptblock.

## Obtaining the IP address of a virtual machine

Before we can connect to a remote machine,
we must obtain its IP address.
(You can use hostnames, but unless you have a very particular lab setup,
your host probably cannot resolve lab VM hostnames.)
You can obtain this from Hyper-V Manager by selecting the VM and clicking on the Networking tab,
or from Powershell with a command like this:

{% highlight powershell %}
<# PS@host #> Get-VM -Name <VM name> | Select-Object -ExpandProperty NetworkAdapters
{% endhighlight %}

## Remoting and trust

By default, PS Remoting is configured to refuse to connect to a server
if the connection cannot be secured.
Machines on the same domain are trusted by default,
but other machines like your lab VMs will not be trusted
and Powershell will refuse to connect to them.
We must disable this security for your VM's IP address in order to connect.
However, this is nothing to be concerned about, for two reasons:

-   The remote server is a VM on your workstation,
    and therefore has no untrusted network (like the Internet)
    where your credentials could be subject to a MITM attack.
-   The lab has just been created and should contain no sensitive data.

You can configure your workstation to disable security for just your lab VM:

{% highlight powershell %}
<# PS@host #> Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value <VM IP address>
{% endhighlight %}

## Remoting to a Hyper-V VM

When remoting directly to a machine,
you can use either an interactive or non-interactive session.
All you should have to do is set a credential and connect:

{% highlight powershell %}
<# PS@host #> Enter-PSSession -ComputerName 10.0.0.1
<# PS@testexample01 #> Write-Output "Hello from $env:ComputerName"
Hello from TESTEXAMPLE01
<# PS@testexample01 #>    # you can run other commands on the remote machine here
<# PS@testexample01 #> exit
<# PS@host #> Invoke-Command -ComputerName 10.0.0.1 -ScriptBlock { Write-Output "Hello from $env:ComputerName" }
Hello from TESTEXAMPLE01
{% endhighlight %}

## Remoting to a VM on a NAT network

You can use PS remoting to connect to machines behind a gateway,
which entails first connecting to the gateway
and then connecting to the destination machine from there.
This is a bit tricky, however.
You must enable a feature called CredSSP,
which allows for passing credentials to the gateway machine for use when connecting to the destination machine.
As mentioned previously, you will need to configure your gateway as a trusted host.

And, perhaps frustratingly, interactive sessions are not supported for the destination machine.
You will have to create an interactive session to your gateway with `Enter-PSSession`,
and then issue individual commands to the destination machine with `Invoke-Command`.

To use PS Remoting with a machine behind a gateway,
first save some values to variables.

{% highlight powershell %}
<# PS@host #> $cred = Get-Credential -Message "Lab user"
<# PS@host #> $gatewayIp = "<Your gateway VM IP address on an External or Internal network>"
<# PS@host #> $destinationIp = "<Your destination VM IP address on the Private network>"
{% endhighlight %}

Next, configure trust as mentioned previously.
Trust the gateway from your host,
and then trust the destination from your gateway.

{% highlight powershell %}
<# PS@host #> Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $gatewayIp
<# PS@host #> Invoke-Command -ComputerName $gatewayIp -Credential $cred -ScriptBlock { Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $using:destinationIp }
{% endhighlight %}

Then, enable CredSSP in client mode on your machine and enable it in server mode on the gateway:

{% highlight powershell %}
<# PS@host #> Enable-WSManCredSSP -Role Client -DelegateComputer $gatewayIp
<# PS@host #> Invoke-Command -ComputerName $gatewayIp -Credential $cred -ScriptBlock { Enable-WSManCredSSP -Role Server }
{% endhighlight %}

After that, set the `AllowFreshCredentialsWhenNTLMOnly` group policy.
This can be done from `gpedit.msc`,
but I prefer to use Powershell:

{% highlight powershell %}
<# PS@host #> New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation -Name AllowFreshCredentialsWhenNTLMOnly -Value 1 -Type DWord -Force
<# PS@host #> New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Type Directory -Force
<# PS@host #> New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly -Name 1 -Value "wsman/$gatewayIp" -Type String -Force
{% endhighlight %}

Then create a session using CredSSP that we can reuse later:

{% highlight powershell %}
<# PS@host #> $sess = New-PSSession -ComputerName $gatewayIp -Authentication CredSSP -Credential $cred
{% endhighlight %}

Then connect to your gateway and execute commands against your destination.
If you connect interactively to the gateway,
variables set on your _host_ are not available,
so we cannot use the `$destinationIp` variable we created earlier:

{% highlight powershell %}
<# PS@host #> $sess | Enter-PSSession
<# PS@gateway #> $cred2 = Get-Credential
<# PS@gateway #> Invoke-Command -ComputerName '<Your destination VM IP address on the private network>' -Credential $cred2 -ScriptBlock { Write-Output "I am connected to $env:COMPUTERNAME" }
I am connected to <destination VM>
{% endhighlight %}

However, if you connect non-interactively,
you can use the `$using:` prefix to reference the same values:

{% highlight powershell %}
<# PS@host #> Invoke-Command -Session $sess -ScriptBlock { Invoke-Command -ComputerName $using:destinationIp -Credential $using:cred -ScriptBlock { Write-Output "I am connected to $env:COMPUTERNAME" } }
I am connected to <destination VM>
{% endhighlight %}

## Remoting and Windows Firewall

Windows Firewall will allow or deny remoting,
depending on the category assigned to the network(s) a machine is connected to.

Networks in Windows have "profiles" which are assigned to one of three "categories":
either "Public", "Private", or "Domain".

1.  A "Public" network is a potentially malicious network,
    like a coffee shop network or a direct Internet connection.

2.  A "Private" network is a network you trust,
    like your home network.

3.  A "Domain" network is a network controlled by an Active Directory domain that the machine is joined to.
    Users cannot assign networks to this category;
    Windows assigns networks to this category automatically if appropriate.

By default, Windows Firewall prohibits remoting from "Public" networks,
but allows it from "Private" and "Domain" networks.

### Setting the network type from the Windows GUI

The first time a machine connects to a given network,
Windows will set the network to "Public" (aka untrusted),
and slide over a dialog pane that says

> Do you want your PC to be discoverable by other PCs and devices on this network?
>
> We recommend allowing this on your home and work networks, but not public ones.

If you click "no", Windows will do nothing;
if you click "yes", Windows will change the network profile category to "Private" and allow remoting.

### Setting the network type from Powershell

You can use the `Set-NetConnectionProfile` cmdlet to change the profile.

## References

- [PowerShell Remoting and the "Double-Hop" Problem](https://blogs.msdn.microsoft.com/clustering/2009/06/25/powershell-remoting-and-the-double-hop-problem/)
- [Making the second hop in PowerShell Remoting](https://docs.microsoft.com/en-us/powershell/scripting/setup/ps-remoting-second-hop?view=powershell-6)
- [Policy does not allow the delegation of user credentials](https://stackoverflow.com/questions/18113651/powershell-remoting-policy-does-not-allow-the-delegation-of-user-credentials)
- [Multi-Hop Support in WinRM](https://msdn.microsoft.com/en-us/library/ee309365(v=vs.85).aspx)
