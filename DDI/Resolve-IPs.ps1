<#
Description: Resolve the hostnames for a list of IP addresses.

To Do:
 - Add version handling so PowerShell 7 can take advantage of parallel for loops
 - Add error handling and logging option
#>

# Add IP addresses, one per line, without additional quotes
$ListOfIPs = @'

'@ -split [Environment]::NewLine
$ResultList = @()


foreach ($IP in $ListOfIPs) {
    $Result = $null

    Write-Host "Resolving $IP" -ForegroundColor Green
    try {
        $Result = [System.Net.Dns]::GetHostEntry($IP)
    } catch {
        $Result = $null
    }

    If ($Result) {
        $ResultList += "$IP," + [string]$Result.HostName
    } Else {
        $ResultList += "$IP,unresolved"
    }
}

$ResultList
