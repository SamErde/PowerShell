Import-Module ActiveDirectory

function Get-UnusedGroup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [string]$SearchBase
    )

    Get-ADGroup -Filter * -Properties members, isCriticalSystemObject -SearchBase $SearchBase | Where-Object {
        ($_.members.count -eq 0 `
            -and !($_.IsCriticalSystemObject) -eq 1 `
            -and $_.DistinguishedName -notmatch 'Exchange Security' `
            -and $_.DistinguishedName -notmatch 'Exchange Install' `
            -and $_.DistinguishedName -notmatch 'Builtin')
    }
}
