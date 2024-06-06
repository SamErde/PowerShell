function Set-DefaultPrinter {
    <#
        .SYNOPSIS
            Set the user's default printer in Windows.
        .DESCRIPTION
            Set the user's default printer in Windows. Shows a list of installed printers if none is specified.
        .PARAMETER PrinterName
            The name of an installed printer to set as the default. 
            Includes tab-autocomplete to select from the currently installed printers.
            If no printer name is specified, a list of installed printers will be shown without making a change.
        .NOTES
            Author: Sam Erde
            Date Modified: 2024-06-06
            Version: 0.1.0

            Dedicated to Matt Dillon, our Intune Engineer Extraordinaire!
    #>
    [CmdletBinding()]
    param (
        # Name of the printer to set as your default. Provides tab-autocomplete with names of installed printers.
        [Parameter()]
        [ArgumentCompleter( {
                param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
                $Script:PrinterNames = (Get-Printer).Name; $Script:PrinterNames
            }
        )]
        [ValidateScript({
                if ($_ -in $Script:PrinterNames) {
                    $true
                }
                else {
                    throw "`n$_ is not a valid printer name. Please use one of the following: $($Script:PrinterNames -join ', ')"
                }
            })]
        [string]
        $PrinterName
    )

    if (-not $PSBoundParameters.ContainsValue($PrinterName)) {
        Get-Printer
        Write-Host "`nNo printer name was specified, so here is a list of installed printers." -ForegroundColor Green -BackgroundColor Black
        return
    }

    $Printer = Get-CimInstance -Class Win32_Printer -Filter "Name=`'$PrinterName`'"
    
    # SetDefaultPrinter if the specified printer name is found
    if ($Printer) {
        Invoke-CimMethod -InputObject $Printer -MethodName SetDefaultPrinter
    }
    else {
        Write-Host "No printer with the name '$PrinterName' was found." -ForegroundColor Yellow -BackgroundColor Black
    }
}
