function Format-TimeSpan {
    <#
    .SYNOPSIS
    Format a TimeSpan object in the most relevant units of time.

    .DESCRIPTION
    Takes a TimeSpan object and returns a formatted string representing the duration in the most appropriate units (microseconds, milliseconds, seconds, minutes, hours, days).

    .PARAMETER TimeSpan
    The TimeSpan object to format.

    .PARAMETER Abbreviate
    If specified, unit labels will be abbreviated (e.g., "ms" instead of "milliseconds").

    .INPUTS
    TimeSpan

    .OUTPUTS
    String representing the formatted timespan.

    .EXAMPLE
    $TimeSpan = New-TimeSpan -Milliseconds 1500
    Format-TimeSpan -TimeSpan $TimeSpan

    Returns: "1.50 seconds"

    .EXAMPLE
    Format-TimeSpan -TimeSpan ([TimeSpan]::Zero) -Abbreviate

    Returns: "0s"

    .EXAMPLE
    New-TimeSpan -Days 1 -Hours 2 -Minutes 30 -Seconds 0 | Format-TimeSpan

    Returns: "1 day 2 hours 30 minutes"

    .NOTES
    Microseconds or milliseconds are not included in the output if the timespan is 1 second or longer.
    Durations of 1 minute or longer do not show fractional (decimal) values.
    Zero-value components are omitted from multi-component output for cleaner formatting.

    Author: Sam Erde, Sentinel Technologies, Inc
    Version: 1.0.0
    Date: 2026-01-04

    .LINK
    New-TimeSpan
    https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/new-timespan
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # The TimeSpan object to format.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'The TimeSpan object to format.')]
        [TimeSpan]$TimeSpan,

        # Optional switch to abbreviate the unit labels in the output.
        [Parameter(Mandatory = $false, HelpMessage = 'If specified, unit labels will be abbreviated (e.g., "ms" instead of "milliseconds").')]
        [switch] $Abbreviate
    )

    begin {
        if ($Abbreviate) {
            $MicrosecondLabel = 'µs'
            $MillisecondLabel = 'ms'
            $SecondLabel = 's'
            $MinuteLabel = 'm'
            $HourLabel = 'h'
            $DayLabel = 'd'
        } else {
            $MicrosecondLabel = ' microseconds'
            $MillisecondLabel = ' milliseconds'
            $SecondLabel = ' seconds'
            $MinuteLabel = ' minutes'
            $HourLabel = ' hours'
            $DayLabel = ' days'
        }
    }

    process {
        $TotalMilliseconds = $TimeSpan.TotalMilliseconds

        if ($TotalMilliseconds -eq 0) {
            # Handle zero timespan
            $Output = "0$SecondLabel"

        } elseif ($TotalMilliseconds -lt 1) {
            $Output = "{0:N2}$MicrosecondLabel" -f ($TotalMilliseconds * 1000)

        } elseif ($TotalMilliseconds -lt 1000) {
            $Output = "{0:N2}$MillisecondLabel" -f $TotalMilliseconds

        } elseif ($TimeSpan.TotalSeconds -lt 60) {
            $Output = "{0:N2}$SecondLabel" -f $TimeSpan.TotalSeconds

        } elseif ($TimeSpan.TotalMinutes -lt 60) {
            # Build output with non-zero components only
            $Output = "{0:N0}$MinuteLabel" -f $TimeSpan.Minutes
            if ($TimeSpan.Seconds -gt 0) { $Output += " {0:N0}$SecondLabel" -f $TimeSpan.Seconds }

        } elseif ($TimeSpan.TotalHours -lt 24) {
            # Build output with non-zero components only
            $Output = "{0:N0}$HourLabel" -f $TimeSpan.Hours
            if ($TimeSpan.Minutes -gt 0) { $Output += " {0:N0}$MinuteLabel" -f $TimeSpan.Minutes }
            if ($TimeSpan.Seconds -gt 0) { $Output += " {0:N0}$SecondLabel" -f $TimeSpan.Seconds }

        } else {
            # Build output with non-zero components only
            $Output = "{0:N0}$DayLabel" -f $TimeSpan.Days
            if ($TimeSpan.Hours -gt 0)   { $Output += " {0:N0}$HourLabel" -f $TimeSpan.Hours }
            if ($TimeSpan.Minutes -gt 0) { $Output += " {0:N0}$MinuteLabel" -f $TimeSpan.Minutes }
            if ($TimeSpan.Seconds -gt 0) { $Output += " {0:N0}$SecondLabel" -f $TimeSpan.Seconds }
        }

    $Output
    }
}
