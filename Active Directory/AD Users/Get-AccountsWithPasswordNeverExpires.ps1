function Get-AccountsWithPasswordNeverExpires {
    <#
    .SYNOPSIS
    Find accounts in Active Directory with passwords set to never expire.

    .DESCRIPTION
    Find accounts in Active Directory with passwords set to never expire.

    .EXAMPLE
    Get-AccountsWithPasswordNeverExpires
    #>
    [CmdletBinding()]
    param ()

    Search-ADAccount -PasswordNeverExpires
}
