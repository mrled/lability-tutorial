Configuration NatNetwork {
    param (
        [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Credential 'Administrator')
    )
    Import-DscResource -Module PSDesiredStateConfiguration

    Import-DscResource -Module xComputerManagement -ModuleVersion 4.1.0.0
    Import-DscResource -Module xNetworking -ModuleVersion 5.7.0.0

    node $AllNodes.Where( {$true}).NodeName {

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

    node $AllNodes.Where( {$_.Role -in 'EDGE'}).NodeName {

        xNetAdapterName "RenamePublicAdapter" {
            NewName    = $node.InterfaceAlias[0];
            MacAddress = $node.Lability_MACAddress[0];
        }
        # Do not specify an IP address for the public adapter so that it gets one via DHCP

        xNetAdapterName "RenameCorpnetAdapter" {
            NewName    = $node.InterfaceAlias[1];
            MacAddress = $node.Lability_MACAddress[1];
        }

        xIPAddress 'CorpnetIPAddress' {
            IPAddress      = $node.CorpnetIPAddress;
            InterfaceAlias = $node.InterfaceAlias[1];
            AddressFamily  = $node.AddressFamily;
            DependsOn      = '[xNetAdapterName]RenameCorpnetAdapter';
        }

        Script "NewNetNat" {
            GetScript            = { return @{ Result = "" } }
            TestScript           = {
                try {
                    Get-NetNat -Name NATNetwork -ErrorAction Stop | Out-Null
                    return $true
                }
                catch {
                    return $false
                }
            }
            SetScript            = {
                New-NetNat -Name NATNetwork -InternalIPInterfaceAddressPrefix "10.0.0.0/24"
            }
            PsDscRunAsCredential = $Credential
            DependsOn            = '[xIPAddress]CorpnetIPAddress';
        }
    }

    node $AllNodes.Where( {$_.Role -NotIn 'EDGE'}).NodeName {

        xIPAddress 'PrimaryIPAddress' {
            IPAddress      = $node.CorpnetIPAddress
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily  = $node.AddressFamily
        }

        xDnsServerAddress 'PrimaryDNSClient' {
            Address        = $node.DnsServerAddress;
            InterfaceAlias = $node.InterfaceAlias;
            AddressFamily  = $node.AddressFamily;
            DependsOn      = '[xIPAddress]PrimaryIPAddress';
        }

        # Do not set the default gateway for the EDGE server to avoid errors like
        # 'New-NetRoute : Instance MSFT_NetRoute already exists'
        # When this configuration was part of the .Where({$true}) stanza above,
        # I got those errors on EDGE all the time.
        xDefaultGatewayAddress 'NonEdgePrimaryDefaultGateway' {
            InterfaceAlias = $node.InterfaceAlias;
            Address        = $node.DefaultGateway;
            AddressFamily  = $node.AddressFamily;
            DependsOn      = '[xIPAddress]PrimaryIPAddress';
        }

    }

    node $Allnodes.Where( {'Firefox' -in $_.Lability_Resource}).NodeName {
        Script "InstallFirefox" {
            GetScript            = { return @{ Result = "" } }
            TestScript           = {
                Test-Path -Path "C:\Program Files\Mozilla Firefox"
            }
            SetScript            = {
                $process = Start-Process -FilePath "C:\Resources\Firefox-Latest.exe" -Wait -PassThru -ArgumentList @('-ms')
                if ($process.ExitCode -ne 0) {
                    throw "Firefox installer at $ffInstaller exited with code $($process.ExitCode)"
                }
            }
            PsDscRunAsCredential = $Credential
        }
    }

}