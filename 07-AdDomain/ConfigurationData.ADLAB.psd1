@{
    AllNodes = @(
        @{
            NodeName                    = '*';
            InterfaceAlias              = 'Ethernet';
            AddressFamily               = 'IPv4';
            DnsConnectionSuffix         = 'aoaglab.vlack.com';
            DnsServerAddress            = '10.0.0.1';
            DefaultGateway              = '10.0.0.2';
            DomainName                  = 'aoaglab.vlack.com';
            PSDscAllowPlainTextPassword = $true;
            PSDscAllowDomainUser        = $true; # Removes 'It is not recommended to use domain credential for node X' messages
            Lability_SwitchName         = 'AOAGLAB-CORPNET';
            Lability_StartupMemory      = 3GB;
            Lability_Media              = "2016_x64_Standard_EN_Eval";
            Lability_Timezone           = "Central Standard Time";
        }
        @{
            NodeName                = 'AOAGLAB-DC1';
            IPAddress               = '10.0.0.1/24';
            DnsServerAddress        = '127.0.0.1';
            Role                    = 'DC';
            Lability_ProcessorCount = 2;
            Lability_Resource           = @(
                'Firefox'
            )
        }
        @{
            NodeName                     = 'AOAGLAB-EDGE1';
            Role                         = 'EDGE'
            Lability_ProcessorCount     = 2

            IPAddress                    = '10.0.0.2/24';

            # SecondaryDnsServerAddress    = '1.1.1.1';
            # SecondaryInterfaceAlias      = 'Ethernet 2';
            # SecondaryDnsConnectionSuffix = 'c4dq.com';

            # This VM acts as a NAT gateway between AOAGLAB-CORPNET and whatever network my WiFi adapter is connected to
            # (Which almost certainly means that AOAGLAB-CORPNET is double-NAT'ed).
            # However, the order that the switches get connected is not deterministic.
            # Therefore, we have to set MAC addresses for each interface,
            # rename each interface based on the MAC address,
            # and then configure IP addresses etc based on the new name of the interface.
            # Technique found here:
            # - https://github.com/VirtualEngine/Lability/blob/dev/Examples/MultipleNetworkExample.ps1
            # - https://github.com/VirtualEngine/Lability/blob/dev/Examples/MultipleNetworkExample.psd1
            # and mentioned here as a solution for our problem:
            # - https://github.com/VirtualEngine/Lability/issues/176
            #
            # Hyper-V MAC address range '00-15-5d-00-00-00' thru '00-15-5d-ff-ff-ff'.
            # WARNING: BE CAREFUL OF DUPLICATE MAC ADDRESSES IF USING EXTERNAL SWITCHES!
            Lability_MACAddress         = @('00-15-5d-cf-01-01', '00-15-5d-cf-01-02')
            Lability_SwitchName         = @('Wifi-HyperV-VSwitch', 'AOAGLAB-CORPNET')
            InterfaceAlias              = @('Public', 'AOAGLAB-CORPNET')

            Lability_Resource           = @(
                'Firefox'
            )
        }
        # @{
        #     NodeName                  = 'AOAGLAB-WEB1';
        #     IPAddress                 = '10.0.0.3/24';
        #     Role                      = 'WEB';
        #     Lability_ProcessorCount     = 1;
        # }
        # @{
        #     NodeName                  = 'AOAGLAB-SQL1';
        #     IPAddress                 = '10.0.0.10/24';
        #     Role                      = 'SQL';
        #     Lability_ProcessorCount     = 1;
        # }
        # @{
        #     NodeName                  = 'AOAGLAB-SQL2';
        #     IPAddress                 = '10.0.0.11/24';
        #     Role                      = 'SQL';
        #     Lability_ProcessorCount     = 1;
        # }
    )
    NonNodeData = @{
        Lability = @{
            Media = @()
            Network = @(
                # Use a *private* switch, not an internal one,
                # so that our Hyper-V host doesn't get a NIC w/ DHCP lease on the corporate network,
                # which can cause networking problems on the host.
                @{ Name = 'AOAGLAB-CORPNET'; Type = 'Private'; }

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
