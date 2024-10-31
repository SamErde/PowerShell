function Get-ADInactiveUsers {

    # DRAFT, WORK IN PROGRESS

    [CmdletBinding()]
    param (
        # Days to consider an account inactive
        [Parameter()]
        [ValidateNotNullOrEmpty]
        [Int16]
        $Days = 90
    )

    begin {
        Import-Module ActiveDirectory
    }

    process {
        $Time = (Get-Date).Adddays( - ($Days))

        Get-ADUser -Filter { LastLogonTimeStamp -lt $time -and enabled -eq $true } -Properties LastLogonTimeStamp |
            Select-Object Name, @{Name = 'LastLogonTimestamp'; Expression = { [DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss') } } |
                Export-Csv .\InactiveUsers.csv -NoTypeInformation
    }

    end {
    }
}
