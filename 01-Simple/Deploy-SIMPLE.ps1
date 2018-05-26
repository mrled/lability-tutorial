[CmdletBinding()] Param(
    [string] $AdminPassword = 'P@ssword123',
    [switch] $DeleteExistingDisks
)

$ErrorActionPreference = "Stop"

Configuration SimpleConfig {
    param (
        [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Credential 'Administrator')
    )
    Import-DscResource -Module PSDesiredStateConfiguration

    Import-DscResource -Module xComputerManagement -ModuleVersion 4.1.0.0
    Import-DscResource -Module xNetworking -ModuleVersion 5.7.0.0

    # Common configuration for all nodes
    node $AllNodes.Where({$true}).NodeName {

        LocalConfigurationManager {
            RebootNodeIfNeeded   = $true;
            AllowModuleOverwrite = $true;
            ConfigurationMode    = 'ApplyOnly';
            CertificateID        = $node.Thumbprint;
        }

        xFirewall 'FPS-ICMP4-ERQ-In' {
            Name        = 'FPS-ICMP4-ERQ-In';
            DisplayName = 'File and Printer Sharing (Echo Request - ICMPv4-In)';
            Description = 'Echo request messages are sent as ping requests to other nodes.';
            Direction   = 'Inbound';
            Action      = 'Allow';
            Enabled     = 'True';
            Profile     = 'Any';
        }

        xFirewall 'FPS-ICMP6-ERQ-In' {
            Name        = 'FPS-ICMP6-ERQ-In';
            DisplayName = 'File and Printer Sharing (Echo Request - ICMPv6-In)';
            Description = 'Echo request messages are sent as ping requests to other nodes.';
            Direction   = 'Inbound';
            Action      = 'Allow';
            Enabled     = 'True';
            Profile     = 'Any';
        }

    }

    node $AllNodes.Where({$_.Role -in 'CLIENT'}).NodeName {

        xComputer 'Hostname' {
            Name = $node.NodeName;
        }

    }

    node $Allnodes.Where({'Firefox' -in $_.Lability_Resource}).NodeName {
        Script "InstallFirefox" {
            GetScript = { return @{ Result = "" } }
            TestScript = {
                Test-Path -Path "C:\Program Files\Mozilla Firefox"
            }
            SetScript = {
                $process = Start-Process -FilePath "C:\Resources\Firefox-Latest.exe" -Wait -PassThru
                if ($process.ExitCode -ne 0) {
                    throw "The Firefox installer at exited with code $($process.ExitCode)"
                }
            }
        }
    }

}

$Error.Clear()

if ($DeleteExistingDisks) {
    $vmDiskPath = Get-LabHostDefault | Select-Object -ExpandProperty DifferencingVhdPath
    do {
        Remove-Item -Path $vmDiskPath\SIMPLE-* -ErrorAction SilentlyContinue -Force
        if (Get-ChildItem -Path $vmDiskPath\SIMPLE-*) {
            Start-Sleep -Seconds 2
        }
    } while (Get-ChildItem -Path $vmDiskPath\SIMPLE-*)
}

$configData = "$PSScriptRoot\ConfigurationData.SIMPLE.psd1"
$adminCred = New-Object -TypeName PSCredential -ArgumentList @(
    "Administrator",
    ($AdminPassword | ConvertTo-SecureString -AsPlainText -Force)
)
$configRoot = Get-LabHostDefault | Select-Object -ExpandProperty ConfigurationPath
& SimpleConfig -ConfigurationData $configData -OutputPath $configRoot -Credential $adminCred -Verbose
Test-LabConfiguration -ConfigurationData $configData -Verbose
Start-LabConfiguration -ConfigurationData $configData -Verbose -Credential $adminCred -IgnorePendingReboot
Start-Lab -ConfigurationData $configData -Verbose
