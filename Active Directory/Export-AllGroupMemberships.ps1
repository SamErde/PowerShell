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
        $Users = Get-ADUser -Filter 'Enabled -eq $true' -Properties EmployeeId, memberOf |
            Select-Object Name, DisplayName, samAccountName, userPrincipalName, EmployeeId, memberOf
        Write-Verbose -Message "  - Found $($Users.Count) users in the domain."

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
        Start-Transcript -Path (Join-Path -Path $PWD -ChildPath "$($MyInvocation.MyCommand).RunHistory.log") -Append -Verbose:$false

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
        Stop-Transcript -Verbose:$false
    } # end
} # end function Export-AllUserGroupMemberships
