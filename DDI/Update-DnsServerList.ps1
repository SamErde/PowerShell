function Update-DnsServerList {
    <#
    .SYNOPSIS
        Check the DNS search order in a client's network interface and replace old DNS server IP addresses with new DNS server IP addresses.
    #>
    [CmdletBinding()]
    param (
        # An array of old DNS server IP addresses
        [Parameter(Mandatory)]
        [ipaddress[]]
        $OldDnsServers,

        # An array of new DNS server IP addresses
        [Parameter(Mandatory)]
        [ipaddress[]]
        $NewDnsServers
    )

    $NetworkAdapters = Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True'
    foreach ($netadapter in $NetworkAdapters) {
        [ipaddress[]]$ClientDnsServerSearchOrder = $netadapter.DnsServerSearchOrder
        if (Compare-Object -ReferenceObject $ClientDnsServerSearchOrder -DifferenceObject $OldDnsServers -IncludeEqual -ExcludeDifferent) {
            $NetAdapterConfig = Get-CimInstance -Class Win32_NetworkAdapterConfiguration -Filter "Index = $._Index"
            $NetAdapterConfig.SetDnsServerSearchOrder($($NewDnsServers.IPAddressToString -join ','))

            IpConfig /FlushDns
            IpConfig /RegisterDns
        }
    }
}
