# Todo

## Todo list

1.  In the Windows 10 Fall Creators Update (Windows 10 build 1709),
    Hyper-V started shipping with a default NAT network.
    That will make configuration easier,
    but my work machine doesn't have 1709 yet so I can't test with it.

2.  I think Lability can apply updates to VHDs before starting VMs...
    look at `C:\Lability\Hotfixes`.

3.  Add lab exercises to all chapters

## New chapter ideas

-   Linux gateway
-   Entire Linux network
-   Linux server joined to Windows domain
-   Syslog forwarding
-   Forward SSH/RDP ports through gateway machine
-   Powershell Web Console on the gateway / webserver behind gateway with port forwarding
-   Remote Desktop web client on the gateway / webserver behind gateway
-   How to create some kind of lab templating system for frequent disposable VMs for e.g. malware analysis
-   Cookbook style organization, maybe for just a sub section of the book?
-   Secrets with GPG + Powershell JSON support

## Reorganization idea - cookbook style

-   Have the recipes be the focus, which can depend on different recipes.
-   For instance, Windows Event Forwarding recipe depends on AD network recipe depends on NAT network recipe...
-   I think this is more useful for people who have some familiarity with Lability
-   Could still have a guided tutorial for Lability concepts... so maybe two sections?
