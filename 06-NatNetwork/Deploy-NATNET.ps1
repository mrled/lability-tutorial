[CmdletBinding()] Param(
    [SecureString] $AdminPassword = (Read-Host -AsSecureString -Prompt "Admin password"),
    [string] $ConfigurationData = (Join-Path -Path $PSScriptRoot -ChildPath ConfigurationData.NATNET.psd1),
    [string] $ConfigureScript = (Join-Path -Path $PSScriptRoot -ChildPath Configure.NATNET.ps1),
    [string] $DscConfigName = "NatNetwork",
    [switch] $IgnorePendingReboot
)

$ErrorActionPreference = "Stop"

. $ConfigureScript
& $DscConfigName -ConfigurationData $ConfigurationData -OutputPath $env:LabilityConfigurationPath -Verbose
Start-LabConfiguration -ConfigurationData $ConfigurationData -Path $env:LabilityConfigurationPath -Verbose -Password $AdminPassword -IgnorePendingReboot:$IgnorePendingReboot
Start-Lab -ConfigurationData $ConfigurationData -Verbose
