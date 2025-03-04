function Get-ADUserTransitiveGroupMembership {
    <#
        .SYNOPSIS
        Get the full transitive group membership of an Active Directory user.

        .DESCRIPTION
        Get the full transitive group membership of an Active Directory user by searching the global catalog. This performs
        a transitive LDAP query which effectively flattens the group membership hierarchy more efficiently than a recursive
        memberOf lookup could.

        .PARAMETER UserDN
        The distinguished name of the user to search for. This is required and it accepts input from the pipeline.

        .PARAMETER Server
        A global catalog domain controller to connect to. This will get a GC in the current forest if none is specified.

        .PARAMETER Port
        Port to connect to the global catalog service on. Defaults to 3269 (using TLS).

        .EXAMPLE
        Get-ADUser -Identity JaneDoe | Get-ADUserTransitiveGroupMembership

        Gets the transitive group membership of the user JaneDoe (include all effective nested group memberships).

        .EXAMPLE
        Get-ADUserTransitiveGroupMembership -UserDN 'CN=Jane Doe,OU=Users,DC=example,DC=com'

        Gets the transitive group membership of the user Jane Doe (include all effective nested group memberships).

        .NOTES
        Author: Sam Erde
        Company: Sentinel Technologies, Inc
        Version: 1.0.0
        Date: 2025-02-27
        #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, HelpMessage = 'The distinguished name of the user to search for.')]
        [string]$UserDN,

        [Parameter(HelpMessage = 'A global catalog domain controller to connect to.')]
        [ValidateScript({ (Test-NetConnection -ComputerName $_ -InformationLevel Quiet -ErrorAction SilentlyContinue).PingSucceeded })]
        [string]$Server = ([System.DirectoryServices.ActiveDirectory.GlobalCatalog]::FindOne([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Forest)).Name,

        # Port to connect to the global catalog service on.
        [Parameter(HelpMessage = 'Port to connect to the global catalog service on. Default is 3268, or 3269 for using TLS.')]
        [ValidateSet(3268, 3269)]
        [int]$Port = 3269
    )

    begin {
        if ($Port -eq 3269) {
            $AltPort = 3268
        } else {
            $AltPort = 3269
        }

        $CurrentProgressPreference = Get-Variable -Name ProgressPreference -ValueOnly
        Set-Variable -Name ProgressPreference 'SilentlyContinue' -Force -Scope Global -ErrorAction SilentlyContinue
        # Check if the global catalog server is available on the specified port.
        if (-not (Test-NetConnection -ComputerName $Server -Port $Port -InformationLevel Quiet -ErrorAction SilentlyContinue)) {
            if (-not (Test-NetConnection -ComputerName $Server -Port $AltPort -InformationLevel Quiet -ErrorAction SilentlyContinue)) {
                throw "Unable to connect to the global catalog server '$Server' on port '$Port' or '$AltPort.'"
            }
        }
        Set-Variable -Name ProgressPreference -Value $CurrentProgressPreference -Force -Scope Global -ErrorAction SilentlyContinue
    }

    process {
        # Set the searcher parameters
        $Filter = "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:=$UserDN))"
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$Server`:$Port")
        $Searcher.Filter = $Filter
        $Searcher.PageSize = 1000
        $Searcher.PropertiesToLoad.Add('DistinguishedName') | Out-Null
        $Results = $Searcher.FindAll()
        Write-Verbose "Found $($Results.Count) groups for ${UserDN}."
        $TransitiveMemberOfGroupDNs = foreach ($result in ($results.properties)) {
            $result['distinguishedname']
        }
    }

    end {
        $TransitiveMemberOfGroupDNs | Sort-Object -Unique
        Remove-Variable Filter, TransitiveMemberOfGroupDNs, Results, Searcher, Server, Port, UserDN -ErrorAction SilentlyContinue
    }
} # end function Get-ADUserTransitiveGroupMembership
