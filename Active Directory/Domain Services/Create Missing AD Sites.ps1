$NetlogonLogPath = 'C:\Windows\Debug\netlogon.log'


Import-Module ActiveDirectory

# Get all subnets from Active Directory Sites and Services
$ADSubnets = Get-ADSubnet -Filter * | Select-Object -ExpandProperty Name

# Read the netlogon.log file
$LogEntries = Get-Content -Path $NetlogonLogPath

# Define a regex pattern to match log entries with IP addresses
$IpPattern = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'

# Initialize an array to store unmatched subnets
$UnmatchedSubnets = New-Object System.Collections.Generic.List[ipaddress]

# Parse the log entries
foreach ($entry in $LogEntries) {
    if ($entry -match $IpPattern) {
        $IpAddress = $matches[0]
        $SubnetMatch = $false

        # Check if the IP address belongs to any AD subnet
        foreach ($subnet in $ADSubnets) {
            if ($IpAddress -like "$subnet*") {
                $SubnetMatch = $true
                break
            }
        }

        # If no match found, add to unmatched subnets
        if (-not $SubnetMatch) {
            $UnmatchedSubnets.Add($IpAddress)
        }
    }
}

# Output the unmatched subnets
if ($UnmatchedSubnets.Count -gt 0) {
    Write-Output 'The following IP addresses are from subnets not listed in Active Directory Sites and Services:'
    $UnmatchedSubnets | Sort-Object | Get-Unique | ForEach-Object { Write-Output $_ }
} else {
    Write-Output 'No unmatched subnets found.'
}
