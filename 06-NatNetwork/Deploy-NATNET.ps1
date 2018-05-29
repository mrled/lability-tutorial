[CmdletBinding()] Param()

$ErrorActionPreference = "Stop"

$configData = "$PSScriptRoot\ConfigurationData.NATNET.psd1"
$adminCred = Get-Credential
. "$PSScriptRoot\Configure.NATNET.ps1"
& NatNetwork -ConfigurationData $configData -OutputPath $env:LabilityConfigurationPath -Credential $adminCred -Verbose
Test-LabConfiguration -ConfigurationData $configData -Verbose
Start-LabConfiguration -ConfigurationData $configData -Path $env:LabilityConfigurationPath -Verbose -Credential $adminCred -IgnorePendingReboot
Start-Lab -ConfigurationData $configData -Verbose
