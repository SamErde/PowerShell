function Get-OverlappingOUName {
    [CmdletBinding()]
    param (

    )

    begin {
        Import-Module ActiveDirectory
    }

    process {
        $OUs = Get-ADOrganizationalUnit -Filter *
        $OverlappingOUNames = $OUs | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }
    }

    end {
        $OverlappingOUNames
    }
}
