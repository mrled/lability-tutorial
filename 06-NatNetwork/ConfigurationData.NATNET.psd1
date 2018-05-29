@{
    AllNodes = @(
        @{
            NodeName                    = '*';
            InterfaceAlias              = 'Ethernet';
            AddressFamily               = 'IPv4';
            DnsServerAddress            = '1.1.1.1';
            PSDscAllowPlainTextPassword = $true;
            PSDscAllowDomainUser        = $true; # Removes 'It is not recommended to use domain credential for node X' messages
            Lability_ProcessorCount     = 1;
            Lability_StartupMemory      = 2GB;
            Lability_Timezone           = "Central Standard Time";
        }
        @{
            NodeName                    = 'NATNET-EDGE1';
            Role                        = 'EDGE'
            CorpnetIPAddress            = '10.0.0.2/24';
            Lability_Media              = "2016_x64_Standard_EN_Eval";

            # Hyper-V MAC address range '00-15-5d-00-00-00' thru '00-15-5d-ff-ff-ff'.
            # WARNING: BE CAREFUL OF DUPLICATE MAC ADDRESSES IF USING EXTERNAL SWITCHES!
            Lability_MACAddress         = @('00-15-5d-cf-01-01', '00-15-5d-cf-01-02')
            Lability_SwitchName         = @('Wifi-HyperV-VSwitch', 'NATNET-CORP')
            InterfaceAlias              = @('Public', 'NATNET-CORP')
        }
        @{
            NodeName                    = 'NATNET-CLIENT1';
            Role                        = 'SERVER';
            CorpnetIPAddress            = '10.0.0.1/24';
            Lability_SwitchName         = 'NATNET-CORP';
            Lability_Media              = 'WIN10_x64_Enterprise_EN_Eval';
            Lability_Resource           = @(
                'Firefox'
            )
        }
    )
    NonNodeData = @{
        Lability = @{
            Media = @()
            Network = @(
                @{ Name = 'NATNET-CORP'; Type = 'Private'; }
            )
            DSCResource = @(
                @{ Name = 'xComputerManagement'; RequiredVersion = '4.1.0.0'; }
                @{ Name = 'xNetworking'; RequiredVersion = '5.7.0.0'; }
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
