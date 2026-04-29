function Get-LAPSPassword {
    <#
    .SYNOPSIS
        Gets LAPS password metadata for computers in an Active Directory search base.

    .DESCRIPTION
        Returns computer names and LAPS password expiration times by default. Use IncludePassword only when the caller
        has a secure process for handling plaintext local administrator passwords.

    .PARAMETER SearchBase
        The distinguished name of the organizational unit or container to search.

    .PARAMETER IncludePassword
        Includes the plaintext ms-Mcs-AdmPwd value in the output.

    .EXAMPLE
        Get-LAPSPassword -SearchBase 'OU=Member Servers,DC=example,DC=com'

    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SearchBase,

        [Parameter()]
        [switch]
        $IncludePassword
    )

    $Properties = @('Name', 'ms-Mcs-AdmPwdExpirationTime')
    if ($IncludePassword) {
        Write-Warning 'Plaintext LAPS passwords will be included in the output. Handle the results securely.'
        $Properties += 'ms-Mcs-AdmPwd'
    }

    Get-ADComputer -SearchBase $SearchBase -Properties $Properties -Filter { Name -notlike '*xen*' } |
        Sort-Object -Property Name |
        Select-Object -Property Name,
        @{ Name = 'Password'; Expression = { if ($IncludePassword) { $_.'ms-Mcs-AdmPwd' } else { '<redacted>' } } },
        @{ Name = 'PasswordExpirationTime'; Expression = { $_.'ms-Mcs-AdmPwdExpirationTime' } }
}
