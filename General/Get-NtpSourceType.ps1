$NTPTypePattern = "^Type: (?'TypeValue'\w+) \({1}\w+\)"
$MatchNTP = w32tm.exe /query /configuration | Select-String -Pattern $NTPTypePattern
$NTPSourceType = $MatchNTP.Matches.Groups[1].Value
$NTPSourceType
# Should return 'NT5DS' for a domain joined machine, 'NTP' for others, etc.

# Get the NTP Server and Type from the registry
$RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time'
[PSCustomObject]@{
    Type              = (Get-ItemProperty -Path "$RegistryPath\Parameters" -Name Type).Type
    Server            = (Get-ItemProperty -Path "$RegistryPath\Parameters" -Name NtpServer).NtpServer
    LastKnownGoodTime = [datetime]::FromFileTime( (Get-ItemProperty -Path "$RegistryPath\Config" -Name LastKnownGoodTime).LastKnownGoodTime )
}
