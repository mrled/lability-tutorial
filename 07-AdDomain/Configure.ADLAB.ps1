
Configuration AdLabConfig {
    param (
        [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Credential 'Administrator')
    )
    Import-DscResource -Module PSDesiredStateConfiguration

    Import-DscResource -Module xActiveDirectory -ModuleVersion 2.17.0.0
    Import-DscResource -Module xComputerManagement -ModuleVersion 4.1.0.0
    Import-DscResource -Module xDHCPServer -ModuleVersion 1.6.0.0
    Import-DscResource -Module xDnsServer -ModuleVersion 1.7.0.0
    Import-DscResource -Module xNetworking -ModuleVersion 5.7.0.0
    Import-DscResource -Module xSmbShare -ModuleVersion 2.0.0.0
    Import-DscResource -Module xWindowsEventForwarding -ModuleVersion 1.0.0.0

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

    node $AllNodes.Where({$_.Role -in 'EDGE'}).NodeName {

        xNetAdapterName "RenamePublicAdapter" {
            NewName     = $node.InterfaceAlias[0];
            MacAddress  = $node.Lability_MACAddress[0];
        }
        # Do not specify an IP address for the public adapter so that it gets one via DHCP

        xNetAdapterName "RenameCorpnetAdapter" {
            NewName     = $node.InterfaceAlias[1];
            MacAddress  = $node.Lability_MACAddress[1];
        }

        xIPAddress 'CorpnetIPAddress' {
            IPAddress      = $node.IPAddress;
            InterfaceAlias = $node.InterfaceAlias[1];
            AddressFamily  = $node.AddressFamily;
            DependsOn      = '[xNetAdapterName]RenameCorpnetAdapter';
        }

        xDnsServerAddress 'CorpnetDNSClient' {
            Address        = $node.DnsServerAddress;
            InterfaceAlias = $node.InterfaceAlias[1];
            AddressFamily  = $node.AddressFamily;
            DependsOn      = '[xIPAddress]CorpnetIPAddress';
        }

        xDnsConnectionSuffix 'CorpnetConnectionSuffix' {
            InterfaceAlias           = $node.InterfaceAlias[1];
            ConnectionSpecificSuffix = $node.DnsConnectionSuffix;
            DependsOn                = '[xIPAddress]CorpnetIPAddress';
        }

        Script "NewNetNat" {
            GetScript = { return @{ Result = "" } }
            TestScript = {
                try {
                    Get-NetNat -Name NATNetwork -ErrorAction Stop | Out-Null
                    return $true
                } catch {
                    return $false
                }
            }
            SetScript = {
                New-NetNat -Name NATNetwork -InternalIPInterfaceAddressPrefix "10.0.0.0/24"
            }
            PsDscRunAsCredential = $Credential
            DependsOn = '[xIPAddress]CorpnetIPAddress';
        }
    }

    node $AllNodes.Where({$_.Role -NotIn 'EDGE'}).NodeName {

        if (-not [System.String]::IsNullOrEmpty($node.IPAddress)) {
            xIPAddress 'PrimaryIPAddress' {
                IPAddress      = $node.IPAddress
                InterfaceAlias = $node.InterfaceAlias
                AddressFamily  = $node.AddressFamily
            }

            if (-not [System.String]::IsNullOrEmpty($node.DnsServerAddress)) {
                xDnsServerAddress 'PrimaryDNSClient' {
                    Address        = $node.DnsServerAddress;
                    InterfaceAlias = $node.InterfaceAlias;
                    AddressFamily  = $node.AddressFamily;
                    DependsOn      = '[xIPAddress]PrimaryIPAddress';
                }
            }

            if (-not [System.String]::IsNullOrEmpty($node.DnsConnectionSuffix)) {
                xDnsConnectionSuffix 'PrimaryConnectionSuffix' {
                    InterfaceAlias           = $node.InterfaceAlias;
                    ConnectionSpecificSuffix = $node.DnsConnectionSuffix;
                    DependsOn                = '[xIPAddress]PrimaryIPAddress';
                }
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

        } #end if IPAddress

    }

    # Configure the AD domain
    node $AllNodes.Where({$_.Role -in 'DC'}).NodeName {

        xComputer 'Hostname' {
            Name = $node.NodeName;
        }

        ## Hack to fix DependsOn with hyphens "bug" :(
        foreach ($feature in @(
                'AD-Domain-Services',
                'GPMC',
                'RSAT-AD-Tools',
                'DHCP',
                'RSAT-DHCP'
            )) {
            WindowsFeature $feature.Replace('-','') {
                Ensure               = 'Present';
                Name                 = $feature;
                IncludeAllSubFeature = $true;
            }
        }

        xADDomain 'ADDomain' {
            DomainName                    = $node.DomainName;
            SafemodeAdministratorPassword = $Credential;
            DomainAdministratorCredential = $Credential;
            DependsOn                     = '[WindowsFeature]ADDomainServices';
        }

        xDhcpServerAuthorization 'DhcpServerAuthorization' {
            Ensure    = 'Present';
            DependsOn = '[WindowsFeature]DHCP','[xADDomain]ADDomain';
        }

        xDhcpServerScope 'DhcpScope10_0_0_0' {
            Name          = 'Corpnet';
            IPStartRange  = '10.0.0.100';
            IPEndRange    = '10.0.0.200';
            SubnetMask    = '255.255.255.0';
            LeaseDuration = '00:08:00';
            State         = 'Active';
            AddressFamily = 'IPv4';
            DependsOn     = '[WindowsFeature]DHCP';
        }

        xDhcpServerOption 'DhcpScope10_0_0_0_Option' {
            ScopeID            = '10.0.0.0';
            DnsDomain          = 'corp.contoso.com';
            DnsServerIPAddress = '10.0.0.1';
            Router             = '10.0.0.2';
            AddressFamily      = 'IPv4';
            DependsOn          = '[xDhcpServerScope]DhcpScope10_0_0_0';
        }

        xADUser User1 {
            DomainName  = $node.DomainName;
            UserName    = 'User1';
            Description = 'Lability Test Lab user';
            Password    = $Credential;
            Ensure      = 'Present';
            DependsOn   = '[xADDomain]ADDomain';
        }

        xADGroup DomainAdmins {
            GroupName        = 'Domain Admins';
            MembersToInclude = 'User1';
            DependsOn        = '[xADUser]User1';
        }

        xADGroup EnterpriseAdmins {
            GroupName        = 'Enterprise Admins';
            GroupScope       = 'Universal';
            MembersToInclude = 'User1';
            DependsOn        = '[xADUser]User1';
        }

    }

    node $AllNodes.Where({$_.Role -NotIn 'DC'}).NodeName {
        # Use user@domain for the domain joining credential
        $upn = "$($Credential.UserName)@$($node.DomainName)"
        $domainCred = New-Object -TypeName PSCredential -ArgumentList ($upn, $Credential.Password);
        xComputer 'DomainMembership' {
            Name       = $node.NodeName;
            DomainName = $node.DomainName;
            Credential = $domainCred
        }
    }

    # Configure Windows Event Forwarding on all source machines
    node $AllNodes.Where({$_.Role -NotIn 'DC'}).NodeName {

        # 1. Get the computer account for the WEF Collector
        # 2. Add that account to the local "Event Log Readers" group on each other server

    }

    # Configure Windows Event Forwarding
    node $AllNodes.Where({$_.Role -in 'DC'}).NodeName {
        xWEFCollector "CreateWefCollector" {
            Ensure = "Present"
            Name = "UniqueIgnoredNameLolWhatever"
        }

        xWEFSubscription "WebSubscription" {
            SubscriptionId = "AdLabSub"
            Ensure = "Present"
            SubscriptionType = "CollectorInitiated"
            DeliveryMode = "Push"
            ReadExistingEvents = $true

            # Create a list of FQDNs like 'dc1.adlab.invalid'
            Address = $configData.AllNodes.Where({$_.NodeName -ne '*'}).NodeName | Foreach-Object -Proces { "$_.$node.DomainName" }

            # Which event logs to request to be forwarded
            Query = @(
                'Application:*'
                'System:*'
                'Microsoft-Windows-Desired State Configuration-Admin:*'
                'Microsoft-Windows-Desired State Configuration-Operational:*'
            )

            DependsOn = "[xWEFCollector]CreateWefCollector"
        }
    }


    node $Allnodes.Where({'Firefox' -in $_.Lability_Resource}).NodeName {
        Script "InstallFirefox" {
            GetScript = { return @{ Result = "" } }
            TestScript = {
                Test-Path -Path "C:\Program Files\Mozilla Firefox"
            }
            SetScript = {
                $ffInstaller = "C:\Resources\Firefox-Latest.exe"
                $firefoxIniFile = "${env:temp}\firefox-installer.ini"
                $firefoxIniContents = @(
                    "QuickLaunchShortcut=false"
                    "DesktopShortcut=false"
                )
                Out-File -FilePath $firefoxIniFile -InputObject $firefoxIniContents -Encoding UTF8
                $startProcParams = @{
                    FilePath = $ffInstaller
                    ArgumentList = @('/INI="{0}"' -f $firefoxIniFile)
                    Wait = $true
                    PassThru = $true
                }
                $process = Start-Process @startProcParams
                if ($process.ExitCode -ne 0) {
                    throw "Firefox installer at $ffInstaller exited with code $($process.ExitCode)"
                }
            }
            PsDscRunAsCredential = $Credential
        }
    }

} #end Configuration Example
