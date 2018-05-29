[CmdletBinding()] Param()

$ErrorActionPreference = "Stop"

$configData = "$PSScriptRoot\ConfigurationData.SIMPLENET.psd1"
. $PSScriptRoot\Configure.SIMPLENET.ps1
& SimpleExpandedConfig -ConfigurationData $configData -OutputPath $env:LabilityConfigurationPath -Verbose

$adminPassword = Read-Host -AsSecureString -Prompt "Admin password"
$adminCred = New-Object -TypeName PSCredential -ArgumentList @("IgnoredUsername", $adminPassword)
Start-LabConfiguration -ConfigurationData $configData -Path $env:LabilityConfigurationPath -Verbose -Credential $adminCred -IgnorePendingReboot
Start-Lab -ConfigurationData $configData -Verbose
