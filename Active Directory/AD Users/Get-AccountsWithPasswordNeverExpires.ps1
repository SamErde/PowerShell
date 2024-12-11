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
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    param ()

    Search-ADAccount -PasswordNeverExpires
}
