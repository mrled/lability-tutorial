@{
    AllNodes = @(
        @{
            NodeName                    = '*';
            InterfaceAlias              = 'Ethernet';
            AddressFamily               = 'IPv4';
            Lability_SwitchName         = "Wifi-HyperV-VSwitch";
            Lability_Media              = 'WIN10_x64_Enterprise_EN_Eval';
            Lability_ProcessorCount     = 1;
            Lability_StartupMemory      = 2GB;
            PSDscAllowPlainTextPassword = $true;
        }
        @{
            NodeName                    = 'CLIENT1';
            Role                        = 'CLIENT';
            IPAddress                   = '10.0.0.1/24';
        }
        @{
            NodeName                    = 'CLIENT1';
            Role                        = 'CLIENT';
            IPAddress                   = '10.0.0.2/24';
        }
    );
    NonNodeData = @{
        Lability = @{
            EnvironmentPrefix = 'SIMPLENET-';
            Network = @(
                @{ Name = 'CORP'; Type = 'Private'; }
            )
            DSCResource = @(
                @{ Name = 'xComputerManagement'; RequiredVersion = '1.9.0.0'; }
                @{ Name = 'xNetworking'; RequiredVersion = '3.2.0.0'; }
            );
        };
    };
};
