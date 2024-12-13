Function Get-GPOsMissingPermission {
    <#
        .SYNOPSIS
        Find Group Policy Objects with Missing Permissions

        .DESCRIPTION
        A script that finds GPOs that are missing permissions for Authenticated Users OR Domain Controllers.
        ...this must have been written before I found GPOZaurr!
    #>
    [CmdletBinding()]
    param ()

    $GPOs = Get-GPO -All

    # Check for GPOs missing Authenticated Users and Domain Computers
    $GPOsMissingPermissions = New-Object System.Collections.ArrayList
    foreach ($item in $GPOs) {
        $GPOPermAuthUsers = Get-GPPermission -Guid $GPO.Id -All | Select-Object -ExpandProperty Trustee | Where-Object { $_.Name -eq 'Authenticated Users' }
        $GPOPermDomainComputers = Get-GPPermission -Guid $GPO.Id -All | Select-Object -ExpandProperty Trustee | Where-Object { $_.Name -eq 'Domain Computers' }

        If (!$GPOPermAuthUsers -and !$GPOPermDomainComputers) {
            $GPOsMissingPermissions.Add($item) | Out-Null
        }
    }
    If ($GPOsMissingPermissions.Count -ne 0) {
        Write-Warning "The following Group Policy Objects do not grant any permissions to the 'Authenticated Users' or 'Domain Computers' groups:"
        foreach ($item in $GPOsMissingPermissions) {
            Write-Host "'$($item.DisplayName)'"
        }
    } Else {
        Write-Host 'There are no GPOs missing permissions for Authenticated Users AND Domain Computers.'
    }

    # Check for GPOs missing Authenticated Users
    $GPOsMissingAuthenticatedUsers = New-Object System.Collections.ArrayList
    foreach ($item in $GPOs) {
        $GPOPermissionForAuthUsers = Get-GPPermission -Guid $item.Id -All | Select-Object -ExpandProperty Trustee | Where-Object { $_.Name -eq 'Authenticated Users' }
        If (!$GPOPermissionForAuthUsers) {
            $GPOsMissingAuthenticatedUsers.Add($item) | Out-Null
        }
    }
    If ($GPOsMissingAuthenticatedUsers.Count -ne 0) {
        Write-Warning "The following Group Policy Objects do not grant any permissions to the 'Authenticated Users' security principal:"
        foreach ($item in $GPOsMissingAuthenticatedUsers) {
            Write-Host "'$($item.DisplayName)'"
        }
    } Else {
        Write-Host 'There are no GPOs missing permissions for Authenticated Users.'
    }
}

<# For using in localized versions (non English) use SIDs:

    $AuthenticatedUsersSID = "S-1-5-11"
    $DomainComputersSID = [string](Get-ADDomain).DomainSID+'-515'

    $GPOPermissionForAuthUsers = Get-GPPermission -Guid $GPO.Id -All | select -ExpandProperty Trustee | ? {$_.SID -eq $AuthenticatedUsersSID}
    $GPOPermissionForDomainComputers = Get-GPPermission -Guid $GPO.Id -All | select -ExpandProperty Trustee | ? {$_.SID -eq $DomainComputersSID}
#>
