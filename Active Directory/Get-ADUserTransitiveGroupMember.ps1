function Get-ADUserTransitiveGroupMembership {
    <#
.SYNOPSIS
Get the full transitive group membership of an Active Directory user.

.DESCRIPTION
Get the full transitive group membership of an Active Directory user by searching the global catalog. This performs a
transitive LDAP query which effectively flattens the group membership hierarchy more efficiently than a recursive memberOf
lookup.

.PARAMETER UserDN
The distinguished name of the user to search for. This is required, and it accepts pipeline input.

.PARAMETER Server
A global catalog domain controller to connect to. This will find a GC automatically if none is specified.

.PARAMETER Port
Port to connect to the global catalog service on. Defaults to 3268.

.EXAMPLE
Get-ADUser -Identity JaneDoe | Select-Object -ExpandProperty DistinguishedName | Get-NestedGroupMembership

Gets the transitive group membership of the user JaneDoe, including all nested group memberships.

.NOTES
Author: Sam Erde
Company: Sentinel Technologies, Inc
Version: 1.0.0
Date: 2025-02-26
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, HelpMessage = 'The distinguished name of the user to search for.')]
        [string]$UserDN,

        [Parameter(HelpMessage = 'A global catalog domain controller to connect to.')]
        [ValidateScript({ Test-Connection -ComputerName $_ -Count 1 -ErrorAction SilentlyContinue })]
        #[string]$Server = (Get-ADDomainController -Discover -Service GlobalCatalog).HostName,
        [string]$Server = ([System.DirectoryServices.ActiveDirectory.GlobalCatalog]::FindOne([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest)).Name,

        # Port to connect to the global catalog service on.
        [Parameter(HelpMessage = 'Port to connect to the global catalog service on. Default is 3268, or 3269 for using TLS.')]
        [ValidateSet(3268, 3269)]
        [int]$Port = 3268
    )

    process {
        # Set the searcher parameters
        $filter = "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:=$UserDN))"
        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$Server`:$Port")
        $searcher.Filter = $filter
        $searcher.PageSize = 1000

        # Properties to include in the results:
        $searcher.PropertiesToLoad.Add('name') | Out-Null
        $searcher.PropertiesToLoad.Add('distinguishedName') | Out-Null
        $searcher.PropertiesToLoad.Add('securityIdentifier') | Out-Null
        $searcher.PropertiesToLoad.Add('objectSid') | Out-Null

        $results = $searcher.FindAll()

        Write-Verbose "Found $($results.Count) groups for ${UserDN}."

        foreach ($result in $results) {
            [PSCustomObject]@{
                GroupName         = $result.Properties['name'][0]
                DistinguishedName = $result.Properties['distinguishedName'][0]
            }
        }
    }
}
