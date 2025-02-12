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
        # Test something
        [Parameter(Mandatory)]
        [Obsolete("'Mode' is being replaced by the more flexible 'Scans', 'OutputType', and 'IncludeFixes' parameters, and will be removed in a future version. Use 'Get-Help Test-Obsolete -Full' for more information.")]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(0, 5)]
        [int16]
        $Mode
    )

    Write-Output "You chose mode ${Mode}."

} # end function Test-Obsolete
