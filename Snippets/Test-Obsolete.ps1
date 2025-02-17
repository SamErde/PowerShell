function Test-Obsolete {
    <#
    .SYNOPSIS
    Test an obsolete parameter.

    .DESCRIPTION
    Test an obsolete parameter.

    .EXAMPLE
    Test-Obsolete -Mode 0

    This example shows how to use the obsolete parameter. The Mode parameter is deprecated and will be removed in a future version.

    .NOTES
    Author: Sam Erde
    Version: 0.0.1
    Modified: 2025-02-12
    #>
    [CmdletBinding()]
    param (
        # Test mode parameter.
        [Parameter(Mandatory)]
        [Obsolete("'Mode' is being replaced by a more flexible set of parameters. It will be removed in a future release.`n`nPlease use 'Get-Help Test-Obsolete' or visit <https://day3bits.com/2025-02-17-using-obsolete-parameters-in-powershell/> for more information.")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 5)]
        [int16]
        $Mode
    )

    Write-Output "You chose mode ${Mode}."

} # end function Test-Obsolete
