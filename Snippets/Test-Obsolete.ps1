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
        [Parameter()]
        [Obsolete("Mode is being replaced by the more flexible 'Scans', 'OutputType', and 'IncludeFixes' parameters, and will be removed in a future version. Use 'Get-Help Test-Obsolete -Full' for more information.")]
        [int16]
        $Mode = 0
    )

    begin {

    } # end begin block

    process {
        Write-Output "You chose mode ${Mode}."
    } # end process block

    end {

    } # end end block

} # end function Test-Function
