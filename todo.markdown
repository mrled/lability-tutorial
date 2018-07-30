# Todo

## Requirements for an initial release

-   Document use of Windows 10 FCU "Default Switch"
    (work laptop was on 1703 when I wrote chapters 1-7)
-   Test all chapters
-   Expand or combine backmatter...
    right now there's 3 sections with one concept each,
    should have either more concepts in each or combine them all into one thing
-   Improve `Deploy-*.ps1` scripts
    -   Do not use the Param() block in the deploy script for Chapter 2,
        but hard code all values instead.
        Also ensure the copied commands in the prose match the lines in the script verbatim.
    -   Continue to use the current version in Chapter 4,
        but add a section about improvements to the deploy script
    -   Add `-DeleteExisting` to the version of the deploy script used in Chapter 4 and later
-   Remove reference to external switch from all chapters (and test)
    -   DONE: Chapter 2
    -   Chapter 3
    -   Chapter 4
    -   Chapter 5
    -   Chapter 6
    -   Chapter 7

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
