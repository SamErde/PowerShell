# WIP

# Get all DNS zones
$zones = Get-DnsServerZone -ComputerName (Get-Domain) | Where-Object { $_.ZoneType -eq 'Primary' }

# Loop through each zone and get SRV records
foreach ($zone in $zones) {
    $srvRecords = Get-DnsServerResourceRecord -ZoneName $zone.ZoneName -RRType SRV | Where-Object { $_.HostName -notmatch 'ldap' -and $_.HostName -notmatch 'gc' -and $_.HostName -notmatch 'kerberos' }
    foreach ($record in $srvRecords) {
        Write-Host "Name: $($record.HostName), Target: $($record.RecordData.Target), Port: $($record.RecordData.Port), Priority: $($record.RecordData.Priority), Weight: $($record.RecordData.Weight)"
        Write-Host "$zone"
    }
}
