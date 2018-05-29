[CmdletBinding()] Param()

$ErrorActionPreference = "Stop"

$configData = "$PSScriptRoot\ConfigurationData.SIMPLE.psd1"
. $PSScriptRoot\Configure.SIMPLE.ps1
& SimpleConfig -ConfigurationData $configData -OutputPath $env:LabilityConfigurationPath -Verbose

$adminPassword = Read-Host -AsSecureString -Prompt "Admin password"
$adminCred = New-Object -TypeName PSCredential -ArgumentList @("IgnoredUsername", $adminPassword)
Start-LabConfiguration -ConfigurationData $configData -Path $env:LabilityConfigurationPath -Verbose -Credential $adminCred
Start-Lab -ConfigurationData $configData -Verbose
