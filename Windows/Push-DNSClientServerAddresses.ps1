Import-Module ActiveDirectory
$servers = Get-ADComputer -SearchBase "" -Server "" -SearchScope Subtree -Filter *
foreach ($server in $servers)
{
    # Connect to the server.
    $serverName = $server.Name
    Write-Output "Connecting to $serverName"
    $s = $null
    try {
        # Create the PSSession. Enter-PSSession is interactive-only and cannot redirect script commands remotely.
        $s = New-PSSession -ComputerName $serverName -ErrorAction Stop
    }
    catch {
        # Log the failure and continue the for loop on the next item.
        Write-Output "Failed connection to $serverName"
        Continue
    }

    # Connected to session. Now update the DNS client server address on any interfaces that currently use a domain controller IP.
    try {
        Invoke-Command -Session $s -ScriptBlock {
            Get-NetIPInterface | Get-DnsClientServerAddress | Where-Object { $_.ServerAddresses -like '10.10.10.*' } |
                Set-DnsClientServerAddress -ServerAddresses ('', '', '') -Verbose
        }
    }
    catch {
        Write-Output "Failed to change the DNS client server address on $serverName"
    }
    finally {
        if ($s) { Remove-PSSession -Session $s }
    }
} # End foreach server loop.
