[CmdletBinding()] Param()

$configData = "$PSScriptRoot\ConfigurationData.ADLAB.psd1"
$adminCred = Get-Credential
& AdLabConfig -ConfigurationData $configData -OutputPath $env:LabilityConfigurationPath -Credential $adminCred -Verbose
Test-LabConfiguration -ConfigurationData $configData -Verbose
Start-LabConfiguration -ConfigurationData $configData -Path $env:LabilityConfigurationPath -Verbose -Credential $adminCred -IgnorePendingReboot
Start-Lab -ConfigurationData $configData -Verbose
