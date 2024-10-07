function Get-PingResultsHashTable {
    [CmdletBinding()]
    param (
        # A server name or array of server names
        [Parameter(Mandatory)]
        [string[]]
        $ServerList
    )

    # Build an ordered hash table that has the server name as the key and the IP address [and any errors] as the value.
    $Servers = [ordered]@{}
    $ServerList | ForEach-Object {
        $Results = Test-NetConnection $_ -InformationLevel Detailed
        if ($Results.PingSucceeded) {
            $Servers.Add( $Results.ComputerName, $($Results.ResolvedAddresses.Where(
                        { $_.AddressFamily -eq 'InterNetwork' }).IPAddressToString) )
        } else {
            $Servers.Add( $Results.ComputerName, "$($Results.ResolvedAddresses.Where(
                {$_.AddressFamily -eq 'InterNetwork'}).IPAddressToString): $($Error[0].Exception.Message)" )
        }
    }
    $Servers
}
