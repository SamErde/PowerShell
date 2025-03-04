[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]
    $ExportDirectory = $PWD
)

process {
    Start-Transcript -Path (Join-Path -Path $PWD -ChildPath "$($MyInvocation.MyCommand).RunHistory.log") -Append -Verbose:$false
    Export-AllUserGroupMemberships -ExportDirectory $ExportDirectory
} # end process block

begin {
    # Import the functions to be used in this script.
    function Export-AllUserGroupMemberships {
        <#
        .SYNOPSIS
        Exports all users' group memberships from the current Active Directory domain.

        .DESCRIPTION
        The purpose of this script is to get the members of all groups in Active Directory in a format that can be easily
        analyzed with tools like Excel or PowerBI. For this purpose, the script exports the data to a JSON file.

        .PARAMETER ExportDirectory
        The directory to create group exports in. Defaults to the 'GroupExports' folder in the current directory.

        .NOTES
        Author: Sam Erde
        Company: Sentinel Technologies, Inc
        Date: 2025-02-24

        NOTE: Be sure to account for nested groups and circular groups!
        #>
        [CmdletBinding()]
        param (
            # The directory to create the exported file in. Defaults to the current directory.
            [Parameter()]
            [ValidateNotNullOrEmpty()]
            [ValidateScript({ Test-Path $_ -IsValid })]
            [string]
            $ExportDirectory = $PWD
        )

        process {
            # Get all users in the domain and their group memberships.
            Write-Verbose -Message 'Getting all enabled users in the domain.'
            Write-Information 'Checking all users'' transitive group memberships in the domain. This will take a while...'
            $Users = Get-ADUser -Filter 'Enabled -eq $true' -Properties EmployeeId |
                Select-Object Name, DisplayName, samAccountName, userPrincipalName, EmployeeId, @{Name = 'Groups'; Expression = {
                        Get-ADUserTransitiveGroupMembership -UserDN $_.DistinguishedName
                    }
                }
            Write-Verbose -Message "  - Found $($UserCount) users in the domain."

            # Export the data to a JSON file.
            $JsonData = $Users | ConvertTo-Json
            $FilePath = (Join-Path -Path $ExportDirectory -ChildPath 'ADUsersGroupMemberships.json')
            Write-Verbose 'Exporting user group memberships to JSON file.'
            try {
                $JsonData | Out-File -FilePath $FilePath -Force
                Write-Verbose '  - Export complete!'
            } catch {
                throw "Unable to create the file '$FilePath'. $_"
            }
        } # process

        # This begin block gets executed first.
        begin {
            # Start-Transcript -Path (Join-Path -Path $PWD -ChildPath "$($MyInvocation.MyCommand).RunHistory.log") -Append -Verbose:$false

            Import-Module ActiveDirectory -Verbose:$false

            # Check if the ExportDirectory exists; if not, create it. Quit if unable to create the directory.
            if (-not (Test-Path -Path $ExportDirectory -PathType Container)) {
                try {
                    New-Item -Path (Split-Path -Path $ExportDirectory -Parent) -Name (Split-Path -Path $ExportDirectory -Leaf) -ItemType Directory
                } catch {
                    throw "Failed to create directory '$ExportDirectory'. $_"
                } # end try
            } # end if
        } # begin

        # This end block gets executed last.
        end {
            Remove-Variable ExportDirectory, FilePath, JsonData, Users -Verbose:$false -ErrorAction SilentlyContinue
            # Stop-Transcript -Verbose:$false
        } # end
    } # end function Export-AllUserGroupMemberships

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
            Set-Variable -Name ProgressPreference 'SilentlyContinue' -Scope Global -Force -ErrorAction SilentlyContinue
            # Check if the global catalog server is available on the specified port.
            if (-not (Test-NetConnection -ComputerName $Server -Port $Port -InformationLevel Quiet -ErrorAction SilentlyContinue)) {
                if (-not (Test-NetConnection -ComputerName $Server -Port $AltPort -InformationLevel Quiet -ErrorAction SilentlyContinue)) {
                    throw "Unable to connect to the global catalog server '$Server' on port '$Port' or '$AltPort.'"
                }
            }
            Set-Variable -Name ProgressPreference -Value $CurrentProgressPreference -Scope Global -Force -ErrorAction SilentlyContinue
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
} # end begin block

end {
    Stop-Transcript -Verbose:$false
    Remove-Variable ExportDirectory -ErrorAction SilentlyContinue
} # end end block
