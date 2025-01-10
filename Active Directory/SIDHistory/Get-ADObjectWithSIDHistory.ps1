function Get-ADObjectWithSIDHistory {
    <#
    .SYNOPSIS
    Get all Active Directory objects that have SID history.

    .DESCRIPTION
    This function gets all Active Directory objects that have SID history. It can optionally be filtered to only get
    user, computer, or group objects.

    .EXAMPLE
     Get-AllAdSidHistory

     This example gets all Active Directory objects that have SID history.

    .EXAMPLE
    Get-AllAdSidHistory -Type User

    This example gets all Active Directory user objects that have SID history.

    .EXAMPLE
    Get-AllAdSidHistory -Type Computer

    This example gets all Active Directory computer objects that have SID history.

    .EXAMPLE
    Get-AllAdSidHistory -Type Group

    This example gets all Active Directory group objects that have SID history.

    .EXAMPLE
    Get-AllAdSidHistory -Type All

    This example gets all Active Directory objects that have SID history, regardless of type.

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.1.0
    Modified: 2025-01-10
    #>
    [CmdletBinding()]
    [OutputType('Microsoft.ActiveDirectory.Management.ADObject[]')]
    param (
        # Type of objects to get. Default is 'All'.
        [Parameter()]
        [ValidateSet('All', 'User', 'Computer', 'Group')]
        [string]
        $Type = 'All'
    )

    begin {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Verbose -Message 'Importing ActiveDirectory module.'
            Import-Module ActiveDirectory
            Write-Verbose -Message '------------------------------'
            Write-Verbose -Message "Beginning ${MyInvocation.InvocationName}..."
        }

        $BaseFilter = 'SIDHistory -like "*"'
        switch ($Type) {
            'User' { $Filter = "$BaseFilter -and objectClass -eq 'user'" }
            'Computer' { $Filter = "$BaseFilter -and objectClass -eq 'computer'" }
            'Group' { $Filter = "$BaseFilter -and objectClass -eq 'group'" }
            'All' { $Filter = $BaseFilter }
        }
    } # end begin

    process {
        # Get all ActiveDirectory objects that have SID history.
        [Microsoft.ActiveDirectory.Management.ADObject[]]$ADObjectList = Get-ADObject -Filter $Filter -Properties SIDHistory | Select-Object * -ExpandProperty SIDHistory
    } # end process

    end {
        $ADObjectList
    } # end end

} # end function
