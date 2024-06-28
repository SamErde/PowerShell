Import-Module ActiveDirectory
$servers = Get-ADComputer -SearchBase "" -Server "" -SearchScope Subtree -Filter *
foreach ($server in $servers)
{
    # Connect to the server.
    $serverName = $server.Name
    Write-Output "Connecting to $serverName"
    try {
        # Create and connect to the PSSession.
        $s = New-PSSession -ComputerName $serverName
        Enter-PSSession $s -ErrorAction SilentlyContinue
    }
    catch {
        # Log the failure and continue the for loop on the next item.
        Write-Output "Failed connection to $serverName"
        Continue
    }

    # Connected to session. Now updated the DNS client server address on any interfaces that currently use a domain controller IP.
    try {
        Get-NetIPInterface | Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses -like '10.10.10.*'} | `
        Set-DnsClientServerAddress -ServerAddresses ("","","") -Verbose
    }
    catch {
        Write-Output "Failed to change the DNS client server address on $servername"
    }
    Exit-PSSession
} # End foreach server loop.
