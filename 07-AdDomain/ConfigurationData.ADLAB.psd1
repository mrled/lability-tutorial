@{
    AllNodes = @(
        @{
            NodeName                    = '*';
            InterfaceAlias              = 'Ethernet';
            AddressFamily               = 'IPv4';
            DnsConnectionSuffix         = 'adlab.invalid';
            DnsServerAddress            = '10.0.0.1';
            DefaultGateway              = '10.0.0.2';
            DomainName                  = 'adlab.invalid';
            PSDscAllowPlainTextPassword = $true;
            PSDscAllowDomainUser        = $true; # Removes 'It is not recommended to use domain credential for node X' messages
            Lability_SwitchName         = 'ADLAB-CORPNET';
            Lability_ProcessorCount     = 1;
            Lability_StartupMemory      = 2GB;
            Lability_Media              = "2016_x64_Standard_EN_Eval";
            Lability_Timezone           = "Central Standard Time";
        }
        @{
            NodeName                = 'ADLAB-DC1';
            IPAddress               = '10.0.0.1/24';
            DnsServerAddress        = '127.0.0.1';
            Role                    = 'DC';
        }
        @{
            NodeName                     = 'ADLAB-EDGE1';
            Role                         = 'EDGE'
            IPAddress                    = '10.0.0.2/24';
            Lability_MACAddress         = @('00-15-5d-cf-01-01', '00-15-5d-cf-01-02')
            Lability_SwitchName         = @('Wifi-HyperV-VSwitch', 'ADLAB-CORPNET')
            InterfaceAlias              = @('Public', 'ADLAB-CORPNET')
        }
        @{
            NodeName                    = 'ADLAB-CLIENT1';
            Role                        = 'CLIENT';
            Lability_Media              = 'WIN10_x64_Enterprise_EN_Eval';
            Lability_Resource           = @(
                'Firefox'
            )
            PSDscAllowPlainTextPassword = $true;
        }
    )
    NonNodeData = @{
        Lability = @{
            Media = @()
            Network = @(
                # Use a *private* switch, not an internal one,
                # so that our Hyper-V host doesn't get a NIC w/ DHCP lease on the corporate network,
                # which can cause networking problems on the host.
                @{ Name = 'ADLAB-CORPNET'; Type = 'Private'; }

                # The Wifi-HyperV-VSwitch is already defined on my machine - do not manage it here
                # If that switch does not exist on your machine, you should define an External switch and set its name here
                # @{ Name = 'Wifi-HyperV-VSwitch'; Type = 'External'; NetAdapterName = 'WiFi'; AllowManagementOS = $true; }
            )

            DSCResource = @(
                @{ Name = 'xActiveDirectory'; RequiredVersion = '2.17.0.0'; }
                @{ Name = 'xComputerManagement'; RequiredVersion = '4.1.0.0'; }
                @{ Name = 'xDhcpServer'; RequiredVersion = '1.6.0.0'; }
                @{ Name = 'xDnsServer'; RequiredVersion = '1.7.0.0'; }
                @{ Name = 'xNetworking'; RequiredVersion = '5.7.0.0'; }
                @{ Name = 'xSmbShare'; RequiredVersion = '2.0.0.0'; }
                @{ Name = 'xWindowsEventForwarding'; RequiredVersion = '1.0.0.0'; }
            )

            Resource = @(
                @{
                    Id = 'Firefox'
                    Filename = 'Firefox-Latest.exe'
                    Uri = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US'
                }
            )
        }
    }
}
