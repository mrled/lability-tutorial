# Todo

## Requirements for an initial release

-   Document use of Windows 10 FCU "Default Switch"
    (work laptop was on 1703 when I wrote chapters 1-7)
-   Test all chapters
-   Expand or combine backmatter...
    right now there's 3 sections with one concept each,
    should have either more concepts in each or combine them all into one thing

## Backlog

I want to write about these things eventually,
but not for the initial release.

-   Investigate `C:\Lability\Hotfixes` - it can apply them to VHDs before starting VMs?
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

### Reorganization idea - cookbook style

-   Have the recipes be the focus, which can depend on different recipes.
-   For instance, Windows Event Forwarding recipe depends on AD network recipe depends on NAT network recipe...
-   I think this is more useful for people who have some familiarity with Lability
-   Could still have a guided tutorial for Lability concepts... so maybe two sections?
