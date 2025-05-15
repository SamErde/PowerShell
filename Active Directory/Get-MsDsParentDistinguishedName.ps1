function Get-MsDsParentDistinguishedName {
    <#
    .SYNOPSIS
    Get the parent OU of an Active Directory object without depending on the ActiveDirectory module.

    .DESCRIPTION
    This function returns the DN of the parent organizational unit of an Active Directory object such as a user or computer.
    You can look up the object by its sAMAccountName, User Principal Name (UPN), or Distinguished Name (DN). The calculated
    attribute 'msDS-ParentDistName' is used to find the parent OU.

    This function uses the .NET System.DirectoryServices namespace, which is available cross-platform and allows for LDAP
    queries without needing the ActiveDirectory module.

    .PARAMETER sAMAccountName
    The sAMAccountName of the object to look up.

    .PARAMETER UserPrincipalName
    The User Principal Name (UPN) of the object to look up.

    .PARAMETER DistinguishedName
    The Distinguished Name (DN) of the object to look up.

    .EXAMPLE
    Get-MsDsParentDistinguishedName -sAMAccountName SamErde

    This example retrieves the DN of the parent OU for the user with the sAMAccountName "SamErde".

    .EXAMPLE
    Get-MsDsParentDistinguishedName -userPrincipalName samerde@day3bits.com

    This example retrieves the DN of the parent OU for the user with the UserPrincipalName "samerde@day3bits.com".

    .EXAMPLE
    Get-ParentDN -DistinguishedName $((Get-ADUser SamErde).DistinguishedName)

    This retrieves the DN of the parent OU for the user with the Distinguished Name "CN=Sam Erde,OU=Users,DC=day3bits,DC=com".
    It also uses the shorter alias name for the function.

    .NOTES
    Some work is still needed on the parameters that accept input from the pipeline. It currently only works with the sAMAccountName parameter.

    Starting Points:

        # Simple method 1:
        $User = ([ADSISearcher]'samAccountName=samerde').FindOne().Properties
        $UserCN = [regex]::Escape($User.cn)
        $UserOU = ($User.distinguishedname).TrimStart("CN=$UserCN,")
        $UserOU

        # Slightly less simple method 2:
        $UserDN = 'CN=Sam Erde,OU=Users,DC=day3bits,DC=com'
        $DirectoryEntry = [ADSI]"LDAP://$UserDN"
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.SearchRoot = $DirectoryEntry
        $Searcher.Filter = "(distinguishedName=$UserDN)"
        $Searcher.PropertiesToLoad.Add('msDS-ParentDistName') | Out-Null
        $Result = $Searcher.FindOne()
        $Result
    #>
    [CmdletBinding(DefaultParameterSetName = 'BysAMAccountName')]
    [OutputType([string])]
    [Alias('Get-ParentDN')]

    param (

        <# ⛓️‍💥 I wanted to include this functionality, but relying on the ActiveDirectory namespace defeats the purpose of not using the ActiveDirectory module. ⛓️‍💥
        [Parameter(ParameterSetName = 'ByInputObject', Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'A user, computer, or ADObject to look up.')]
        [ValidateScript({
                if ($_ -is [Microsoft.ActiveDirectory.Management.ADEntity] -or $_ -is [Microsoft.ActiveDirectory.Management.ADAccount] -or $_ -is [Microsoft.ActiveDirectory.Management.ADObject] -or $_ -is [Microsoft.ActiveDirectory.Management.ADComputer] -or $_ -is [Microsoft.ActiveDirectory.Management.ADUser]) {
                    return $true
                } else {
                    throw "The InputObject parameter requires an ADUser, ADComputer, or ADObject object type as input. A $($_.GetType().Name) was provided."
                }
            })]
        [Microsoft.ActiveDirectory.Management.ADEntity] $InputObject,
        #>

        [Parameter(ParameterSetName = 'BysAMAccountName', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'The sAMAccountName of the object to look up.')]
        [string] $sAMAccountName,

        [Parameter(ParameterSetName = 'ByUserPrincipalName', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'The User Principal Name (UPN) of the object to look up.')]
        [string] $UserPrincipalName,

        [Parameter(ParameterSetName = 'ByDistinguishedName', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'The Distinguished Name (DN) of the object to look up.')]
        [string] $DistinguishedName
    )

    begin {}

    process {
        # Find the base distinguished name (DN) of the Active Directory forest to search in.
        $BaseDN = ([ADSI]'LDAP://RootDSE').defaultNamingContext
        $SearchRoot = [ADSI]"LDAP://$BaseDN"

        # Define the LDAP filter based on the parameter provided or lookup the DistinguishedName (DN) directly if provided.
        # Escape the input parameter values to handle any special characters. DNS are usually already escaped.
        switch ($PSCmdlet.ParameterSetName) {
            'BysAMAccountName' {
                $sAMAccountName = [regex]::Escape($sAMAccountName)
                $Filter = "(sAMAccountName=$sAMAccountName)"
            }
            'ByUserPrincipalName' {
                #$UserPrincipalName = [regex]::Escape($UserPrincipalName) # this broke it somehow
                $Filter = "(&(objectCategory=person)(objectClass=user)(userPrincipalName=$UserPrincipalName))"
            }
            'ByDistinguishedName' {
                $Filter = "(distinguishedName=$DistinguishedName)"
                $SearchRoot = [ADSI]"LDAP://$DistinguishedName"
            }
        }

        # Create a DirectorySearcher object to search for the AD object and its msDS-ParentDistName attribute.
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.SearchRoot = $SearchRoot
        $Searcher.Filter = $Filter
        $Searcher.SearchScope = [System.DirectoryServices.SearchScope]::Subtree
        $Searcher.PropertiesToLoad.Add('msDS-ParentDistName') | Out-Null

        # Error handling for the DirectorySearcher object's FindOne method.
        try {
            # Perform the search and retrieve the msDS-ParentDistName attribute.
            $Result = $Searcher.FindOne()

            # Check if the result is not null and contains the msDS-ParentDistName attribute.
            if ($null -ne $Result) {
                # Get the msDS-ParentDistName attribute from the result.This contains the DN of the parent OU.
                $Parent = $Result.Properties['msds-parentdistname']
                if ($Parent) {
                    # The result is an array of properties, so we need to return the first element.
                    return $Parent[0]
                } else {
                    Write-Warning 'A result was found while searching for the Active Directory object, but the msDS-ParentDistName attribute was not present. You may not have permission to read the msDS-ParentDistName attribute or are not connected to a global catalog server.'
                    return $null
                }
            } else {
                # $Result is null, meaning no matching object was found.
                Write-Warning 'No matching object was found in Active Directory.'
                return $null
            }
        } catch {
            # The search failed, possibly due to an invalid filter or other issues.
            Write-Error "An error occurred: $_"
            return $null
        }
    } # End of process block

    end {
        # Cleanup: Dispose of the DirectorySearcher object to free up resources.
        if ($Searcher) {
            $Searcher.Dispose()
        }
        # Remove all variables to free up memory.
        Remove-Variable -Name BaseDN, SearchRoot, Filter, Searcher, Result, Parent -ErrorAction SilentlyContinue
    }
}
