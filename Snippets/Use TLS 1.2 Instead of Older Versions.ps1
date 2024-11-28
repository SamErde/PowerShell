<#
    From the dirteam blog - the things that are better left unspoken
    HOWTO: Disable weak protocols, cipher suites and hashing algorithms on Web Application Proxies, AD FS Servers and
    Windows Servers running Azure AD Connect [(or anything!)]
    https://dirteam.com/sander/2019/07/30/howto-disable-weak-protocols-cipher-suites-and-hashing-algorithms-on-web-application-proxies-ad-fs-servers-and-windows-servers-running-azure-ad-connect/
#>

# Enable TLS 1.2
$SChannelRegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'

New-Item $SChannelRegPath"\TLS 1.2\Server" -Force
New-Item $SChannelRegPath"\TLS 1.2\Client" -Force

New-ItemProperty -Path $SChannelRegPath"\TLS 1.2\Server" -Name Enabled -Value 1 -PropertyType DWORD
New-ItemProperty -Path $SChannelRegPath"\TLS 1.2\Server" -Name DisabledByDefault -Value 0 -PropertyType DWORD

New-ItemProperty -Path $SChannelRegPath"\TLS 1.2\Client" -Name Enabled -Value 1 -PropertyType DWORD
New-ItemProperty -Path $SChannelRegPath"\TLS 1.2\Client" -Name DisabledByDefault -Value 0 -PropertyType DWORD

# Note: The DisabledByDefault registry value doesn't mean that the protocol is disabled by default. It means the protocol is not advertised as available by default during negotiations, but is available if specifically requested.

# Configure .NET Applications to Use TLS 1.1 and TLS 1.2
$DotNET4WoWPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319'
New-ItemProperty -Path $DotNET4WoWPath -Name SystemDefaultTlsVersions -Value 1 -PropertyType DWORD
New-ItemProperty -Path $DotNET4WoWPath -Name SchUseStrongCrypto -Value 1 -PropertyType DWORD

$DotNET4Path = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
New-ItemProperty -Path $DotNET4Path -Name SystemDefaultTlsVersions -Value 1 -PropertyType DWORD
New-ItemProperty -Path $DotNET4Path -Name SchUseStrongCrypto -Value 1 -PropertyType DWORD

# Disable TLS 1.0 and TLS 1.1
New-Item $SChannelRegPath -Name 'TLS 1.0'
New-Item $SChannelRegPath"\TLS 1.0" -Name SERVER
New-ItemProperty -Path $SChannelRegPath"\TLS 1.0\SERVER" -Name Enabled -Value 0 -PropertyType DWORD

New-Item $SChannelRegPath"\TLS 1.1\Server" -Force
New-ItemProperty -Path $SChannelRegPath"\TLS 1.1\Server" -Name Enabled -Value 0 -PropertyType DWORD
New-ItemProperty -Path $SChannelRegPath"\TLS 1.1\Server" -Name DisabledByDefault -Value 0 -PropertyType DWORD

New-Item $SChannelRegPath"\TLS 1.1\Client" -Force
New-ItemProperty -Path $SChannelRegPath"\TLS 1.1\Client" -Name Enabled -Value 0 -PropertyType DWORD
New-ItemProperty -Path $SChannelRegPath"\TLS 1.1\Client" -Name DisabledByDefault -Value 0 -PropertyType DWORD

# Prompt to reboot the server now or later?

# Show TLS Cipher Suites
Get-TlsCipherSuite | Format-Table Name

# Disable Weak Cipher Suites and Algorithm Hashes on Windows Server 2016
Disable-TlsCipherSuite -Name 'TLS_DHE_RSA_WITH_AES_256_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_DHE_RSA_WITH_AES_128_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_AES_256_GCM_SHA384'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_AES_128_GCM_SHA256'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_AES_256_CBC_SHA256'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_AES_128_CBC_SHA256'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_AES_256_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_AES_128_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_3DES_EDE_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_DHE_DSS_WITH_AES_256_CBC_SHA256'
Disable-TlsCipherSuite -Name 'TLS_DHE_DSS_WITH_AES_128_CBC_SHA256'
Disable-TlsCipherSuite -Name 'TLS_DHE_DSS_WITH_AES_256_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_DHE_DSS_WITH_AES_128_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_RC4_128_SHA'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_RC4_128_MD5'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_NULL_SHA256'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_NULL_SHA'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_AES_256_GCM_SHA384'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_AES_128_GCM_SHA256'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_AES_256_CBC_SHA384'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_AES_128_CBC_SHA256'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_NULL_SHA384'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_NULL_SHA256'
