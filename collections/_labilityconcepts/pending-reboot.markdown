---
---

# Pending reboot

`Start-LabConfiguration` checks whether your lab host needs to reboot, and will fail to build the lab if it does.
That error might look like this:

```
WARNING: [10:49:19 AM] A pending reboot is required. Please reboot the system and re-run the configuration.
Host configuration test failed and may have a pending reboot.
At line:137 char:13
+             throw $localized.HostConfigurationTestError;
+             ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (Host configurat...pending reboot.:String) [], RuntimeException
    + FullyQualifiedErrorId : Host configuration test failed and may have a pending reboot.
```

## Cause of pending reboot

Lability uses a local copy of Microsoft's `xPendingReboot` DSC resource.
See the `Get-TargetResource` function of
`DSCResources\xPendingReboot\DSCResources\MSFT_xPendingReboot\MSFT_xPendingReboot.psm1`
for the implementation.

At the time of this writing,
that module triggers a pending reboot warning based on:

1.  Component based servicing
2.  Any pending Windows Updates
3.  Any pending file renames
    (this can occur if you attempt to rename files that are in use,
    such as when running uninstallers)
4.  Any pending computer renames (including domain/workgroup changes)

In my experience, even normal use of my laptop could trigger a pending reboot error,
usually related to pending file renames.

## `-IgnorePendingReboot` parameter

`Start-LabConfiguration` has a `-IgnorePendingReboot` parameter which will bypass this check entirely.

The documentation provides no hints as to what kinds of problems this can solve.
That said, I have not experienced any problems by passing `-IgnorePendingReboot` every time.
