# Chapter 3: Debugging
{:.no_toc}

In this chapter, we discuss debugging problems with a Lability configuration.

## On this page
{:.no_toc}

* TOC
{:toc}

## Debugging problems before `Start-Lab`

If Lability is throwing errors before you start your lab,
you will have to go spelunking in Powershell's `$Error` variable.

### Deleting existing virtual disks before redeploying

Windows file locking semantics 🙄

If you deploy a lab,
find a problem,
and need to redploy,
you may find that the lab's virtual disks (found in `$env:LabilityDifferencingVhdPath`) are locked.
This will result in an error when Lability tries to overwrite them with a new version.

To get around this, you basically just have to wait for a few seconds and try again.
I found myself having to do this so often that I automated it.
This short script will attempt to delete the `CLIENT1` VHD from our previous chapter
ever two seconds.
When it's finished, it will run `Start-LabConfiguration`.

**WARNING**: You should check the contents of `$env:LabilityDifferencingVhdPath`
before running this script!
That location contains virtual disks for _all_ VMs across _all_ labs on your machine,
so if there are other VMs whose names start with `CLIENT`,
it will delete their disks as well.

{% highlight powershell %}
$diskFilenamePrefix = "CLIENT1"
do {
    Remove-Item -Path "${env:LabilityDifferencingVhdPath}\${diskFilenamePrefix}*" -ErrorAction SilentlyContinue -Force
    sleep 2
} while (Get-ChildItem -Path "${env:LabilityDifferencingVhdPath}\${diskFilenamePrefix}*")
Start-LabConfiguration -ConfigurationData $configData -Verbose -Credential $adminCred
{% endhighlight %}

### Filtering `$Error`

Lability emits dozens of non-halting errors even when everything is working correctly.
For instance, it frequently checks for a `CustomMedia.json` file,
and records an error if that file doesn't exist.
(You can use that file to define custom Windows installation media;
see the `about_Media` help topic for more information.)

When troubleshooting, I've found it helpful to filter `$Error` like this:

{% highlight powershell %}
$Error | Where-Object -FilterScript {
    $_ -NotMatch 'CustomMedia.json' -and
    $_ -NotMatch 'HKLM:\\SOFTWARE\\Microsoft\\PowerShell\\3\\DSC'
}
{% endhighlight %}

This still contains some noise,
but cuts out dozens and dozens of errors that are probably not part of whatever problem you are having.

### Using Show-ErrorReport.ps1

To make this a bit more readable, I have included a [`Show-ErrorReport.ps1` script below](#show-errorreportps1).
This takes the records in `$Error` and makes them more easily read by humans.
This script is entirely optional,
so if there is some other way you prefer to investigate `$Error` records,
by all means skip it.

You can run the script as simple `.\Show-ErrorReport.ps1` and it will report on all errors.
To filter the errors as we do above,
you could run it like this instead:

{% highlight powershell %}
.\Show-ErrorReport.ps1 -ErrorList $($Error | Where-Object -FilterScript {
    $_ -NotMatch 'CustomMedia.json' -and
    $_ -NotMatch 'HKLM:\\SOFTWARE\\Microsoft\\PowerShell\\3\\DSC'
}) | more
{% endhighlight %}

## Debugging a lab VM that never shows the logon screen

When you run the `Start-Lab` command,
Lability starts all the VMs it created for your lab.
You can launch the `Hyper-V Manager` application and see the virtual console for each VM.
The console will display the Hyper-V logo and a spinner
while the machine is applying the DSC configuration,
and will show the logon screen once the DSC configuration is fully applied.
Unfortunately, if the DSC configuration does not complete successfully,
the logon screen will never appear,
and there will be no obvious way to troubleshoot problems.

This section describes troubleshooting methods that I turn to when this happens.

### The sledgehammer - reset the VM

Resetting the VM (right click on the VM -> `Reset`)
is akin to pulling the power out of a physical computer and then turning it back on.

This means that your configuration will not have finished applying,
and potentially something could have gotten corrupted.
It also has the useful side effect of booting to a logon screen,
because DSC only tries to apply the configuration at first boot.

Once you've done this, the machine will reboot,
and you can log on and try to determine the source of the problem.

### Relevant logs

There are two places to check for logs:

1.  Lability logs to a file in the `C:\Bootstrap` directory called `Bootstrap-<DATESTAMP>.log`

2.  Powershell DSC logs to the Windows event system,
    visible in Event Viewer under
    `Applications and Services Logs\Microsoft\Windows\Desired State Configuration`

### Powershell remoting

If your VM came up enough to get an IP address,
and it is on an Internal or External (but not Private) Hyper-V switch,
then you may be able to log on using Powershell Remoting
(which uses Windows Remote Management, or WinRM, under the hood).

(This is a great reason to configure networking as early as possible in your DSC configurations!)

To attempt this, follow the following steps:

1.  Get the IP address of the VM
2.  Configure your host to allow insecure WinRM connections to the VM with something like
    `Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value <VM IP address>`
3.  Connect to the VM with `Enter-PSSession`

These steps are laid out in more detail in [Powershell Remoting](../backmatter/concepts/powershell/remoting)

If that worked, you are now connected to the VM and can explore its filesystem,
including the Bootstrap log referenced above.

## Lab exercises and files

1.  Explore the `Show-ErrorReport` script included here.
    Generate some errors in Powershell,
    use `Show-ErrorReport` to see the errors,
    and compare the output of that script with the result of merely typing `$Error` at the prompt.

    Note that `Show-ErrorReport` works with any Powershell error,
    and has no logic specific to Lability.

2.  Filter errors for the `Show-ErrorReport` script.
    Since `Show-ErrorReport` is not specific to Lability,
    you can generate your own errors for filtering.
    For instance, you might try:

    -   Listing nonexistent directories like `Get-ChildItem -Path C:\nonexistent`
    -   Throwing errors directly with `throw "this is an error"`

3.  Modify the example configuration from [Chapter 2](../02-Simple)
    to hang at the Hyper-V boot screen.

    One way to do that might be to change the `xComputer` resource to attempt to join a domain.
    That might look like this:

        xComputer 'Hostname' {
            Name       = $node.NodeName;
            DomainName = "example.com"
            Credential = New-Object -TypeName PSCredential -ArgumentList @(
                "fake@example.com"
                "fakePassword@123" | ConvertTo-SecureString -AsPlainText -Force
            )
        }

    With this configuration,
    the VM will wait until it can join a domain before presenting the logon screen.
    Assuming there is no `example.com` domain on your local network
    that has a user named `fake` with a password of `fakePassword@123`,
    attempting to join that domain will fail,
    and the VM will hang indefinitely at the Hyper-V boot screen.

4.  Reset a VM that is hung at the Hyper-V boot screen and troubleshoot it

    -   Deploy the example configuration you just created
    -   Wait for the VM to hang
    -   Reset the VM
    -   Log in
    -   Find the logs that detail the hang

5.  Use Powershell Remoting to connect to a machine that is hung at the Hyper-V boot screen

    -   Redeploy the example configuration you just created
        (deleting the old deployment if it still exists)
    -   Wait for the VM to hang
    -   Log in using Powershell Remoting
    -   Find the logs that detail the hang

### [Show-ErrorReport.ps1](https://github.com/mrled/lability-tutorial/tree/master/03-Debugging/Show-ErrorReport.ps1)

{% highlight powershell %}
{% include_relative Show-ErrorReport.ps1 %}
{% endhighlight %}
