<#
-------------------------------------------------------------------------------------------
    This was an old work in progress that I found. Is it finished? Need time to review.
-------------------------------------------------------------------------------------------
#>


# Get a list of name (DNS) servers used in the current computer's domain.
$DnsServers = (Resolve-DnsName -Type NS ((Get-CimInstance CIM_ComputerSystem).Domain)).NameHost

function Get-DNSZone {
# Get DNS zones from all servers and return a sorted list of unique zone entries (eliminates DSIntegrated copies).

    # Ignore special local zones on DC/DNS Servers. (Need reference explaning their usage.)
    $IgnoreZoneNames = @("0.in-addr.arpa","127.in-addr.arpa","255.in-addr.arpa")

    $DnsServers | ForEach-Object {
        $DnsZones += Get-DNSServerZone -ComputerName $_ | Where-Object {$_.ZoneName -notin $IgnoreZoneNames}
    }
    Return $DnsZones | Sort-Object ZoneName -Unique
}

# Get the zone list along with a list of non DS-integrated zones (report on these) and a list of reverse lookup zones.
$AllDNSZones = Get-DNSZone
    $NonDSIntegratedZones = $AllDNSZones | Where-Object {$_.IsDsIntegrated -eq $False}
    $ReverseLookupZones = $AllDNSZones | Where-Object {$_.IsReverseLookupZone -eq $True}


function Test-PTRRecord ($ZoneName, $DNSServer) {
# Take a reverse lookup zone name and optionally a DNS server name as input,
# then test all PTR records against their expected A records in forward lookup zones.

    # If no DNS server is specified, choose one at random from the previously discovered list.
    if (!$DnsServer) { $DnsServer = Get-Random -InputObject $DnsServers }

    # Quit the function with an error if the zone name provided is not a reverse lookup zone.
    if ( -not (Get-DNSServerZone -ComputerName $DNSServer -ZoneName $ZoneName).IsReverseLookupZone ) {
        Write-Error -Message "`"$ZoneName`" is not a reverse lookup zone and cannot be used with the Test-PTRRecord function."
        break
    }

    # Get IP address octets abstracted in the zone name because the PTR hostnames only capture a partial IP address that excludes this prefix.
    $ZonePrefix = "." + $ZoneName -replace ('.in-addr.arpa','')

    # Get all PTR records from the specified zone name and DNS server.
    $PTRs = Get-DnsServerResourceRecord -ComputerName $DNSServer -ZoneName $ZoneName -RRType Ptr
    # $PTRs = $Zone | Get-DnsServerResourceRecord -ComputerName $DNSServer -RRType Ptr # This one pipes a zone object instead of zone name.

    Write-Host -ForegroundColor Yellow "Testing zone: $ZoneName"
    Write-Host -ForegroundColor Yellow "Zone prefix: $ZonePrefix"
    Write-Host -ForegroundColor Yellow "Record Count: $($PTRs.Count)"

    # Loop through each PTR record to perform the actual validation.
    foreach ($record in $PTRs) {

        # NOTE: The hostname in a PTR record is the reversed IP address and the RecordData is its target A record's host name.

        # Normalize the reversed IP address after "reconstituting" it with its zone prefix.
        $IPAddress  = ReverseIPAddress("$($record.Hostname)$ZonePrefix")
        # Get the expected host name (A record) from the PTR's record data.
        $TargetName = ($record | Select-Object -ExpandProperty RecordData).PtrDomainName

        # Should first check to see if an A record exists, then check for a name match, then ping it.
        $TestResults = Test-NetConnection -ComputerName $TargetName
        if ($TestResults.PingSucceeded -eq $false) {
            Write-Output "The PTR target for $IPAddress `($TargetName`) did not respond to a ping."
            # LOG
            #break
        }

        if ($TestResults.RemoteAddress -ne "$IPAddress") {
            Write-Output "PTR target for $IPAddress `($TargetName`) does not did not match the hostname's A record data $($TestResults.RemoteAddress)."
        }

    } # End foreach PTR loop
} # End Test-PTRRecord function

function ReverseIPAddress ($IPAddress) {
# Convert an IP address to a reverse IP address or vice versa.
    $IPBytes = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
    [Array]::Reverse($IPBytes)
    $IPBytes -join '.'
}
