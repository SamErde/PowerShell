#WIP

# Get all DC records and test them for connectivity
Get-ADDomainController -Filter * | Sort-Object Name | Format-Table Name, Enabled, IsGlobalCatalog, ComputerObjectDN
foreach ($dc in $dcs) {
    Test-NetConnection $dc.DnsHostname | Select-Object ComputerName, RemoteAddress, PingSucceeded | Format-Table
}
