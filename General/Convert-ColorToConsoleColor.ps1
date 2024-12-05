function Convert-ColorToConsoleColor {
    <#
    .SYNOPSIS
    Convert a color ([System.Drawing.Color]) to the closest matching console color name ([System.ConsoleColor]).

    .DESCRIPTION
    Convert a color ([System.Drawing.Color]) to the closest matching console color name ([System.ConsoleColor]).

    .PARAMETER Color
    An [A,]R,G,B color value or object.

    .EXAMPLE
    $Color = [System.Drawing.Color]::FromArgb(50, 55, 20)
    $ConsoleColor = Convert-ColorToConsoleColor -Color $Color
    Write-Output $ConsoleColor

    .EXAMPLE
    Convert-ColorToConsoleColor -Color ([System.Drawing.Color]::FromArgb(50, 55, 20))

    .EXAMPLE
    Convert-ColorToConsoleColor -Color ([System.Drawing.Color]::DarkOrchid)

    .EXAMPLE
    [System.Drawing.Color]::BurlyWood | Convert-ColorToConsoleColor

    .EXAMPLE
    $psISE.Options.ConsolePaneTextBackgroundColor.ToString() | Convert-ColorToConsoleColor

    Converts the value of the PowerShell ISE console pane text background color to the closest matching console color.

    .OUTPUTS
    System.ConsoleColor

    .NOTES
    Author: Sam Erde
    Version: 1.0.0
    Modified: 2024-12-04

    To Do: Add tab-autocomplete for color names.
    #>
    [CmdletBinding()]
    [OutputType([System.ConsoleColor])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ArgumentCompleter({ ColorArgumentCompleter @args })]
        [System.Drawing.Color]
        $Color
    )

    $ConsoleColorList = [Enum]::GetValues([System.ConsoleColor])
    $ClosestColor = [System.ConsoleColor]::Black
    $SmallestDistance = [double]::MaxValue

    # Loop through each console color and find the closest match to the input color.
    foreach ($ConsoleColor in $ConsoleColorList) {
        $ConsoleColorValue = [System.Drawing.Color]::FromName($ConsoleColor.ToString())
        $Distance = [math]::Sqrt(
            [math]::Pow($color.R - $ConsoleColorValue.R, 2) +
            [math]::Pow($color.G - $ConsoleColorValue.G, 2) +
            [math]::Pow($color.B - $ConsoleColorValue.B, 2)
        )

        if ($Distance -lt $SmallestDistance) {
            $SmallestDistance = $Distance
            $ClosestColor = [System.ConsoleColor]$ConsoleColor
        }
    }

    $ClosestColor
}

function ColorArgumentCompleter {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $KnownColors = [System.Enum]::GetValues([System.Drawing.KnownColor])
    $ColorNames = $KnownColors | ForEach-Object {
        [System.Drawing.Color]::FromKnownColor($_).Name
    }
    $ColorNames
}
