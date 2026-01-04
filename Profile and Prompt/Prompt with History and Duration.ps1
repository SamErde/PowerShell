function Prompt {
# A custom PowerShell prompt that includes command history ID, previous command duration, and current working directory.
# Uses the Format-TimeSpan function to format the duration.
    function Format-TimeSpan {
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

            # Handle zero timespan
            if ($TotalMilliseconds -eq 0) {
                "0$SecondLabel"
            } elseif ($TotalMilliseconds -lt 1) {
                "{0:N2}$MicrosecondLabel" -f ($TotalMilliseconds * 1000)
            } elseif ($TotalMilliseconds -lt 1000) {
                "{0:N2}$MillisecondLabel" -f $TotalMilliseconds
            } elseif ($TimeSpan.TotalSeconds -lt 60) {
                "{0:N2}$SecondLabel" -f $TimeSpan.TotalSeconds
            } elseif ($TimeSpan.TotalMinutes -lt 60) {
                # Build output with non-zero components only
                $Output = "{0:N0}$MinuteLabel" -f $TimeSpan.Minutes
                if ($TimeSpan.Seconds -gt 0) {
                    $Output += " {0:N0}$SecondLabel" -f $TimeSpan.Seconds
                }
                $Output
            } elseif ($TimeSpan.TotalHours -lt 24) {
                # Build output with non-zero components only
                $Output = "{0:N0}$HourLabel" -f $TimeSpan.Hours
                if ($TimeSpan.Minutes -gt 0) {
                    $Output += " {0:N0}$MinuteLabel" -f $TimeSpan.Minutes
                }
                if ($TimeSpan.Seconds -gt 0) {
                    $Output += " {0:N0}$SecondLabel" -f $TimeSpan.Seconds
                }
                $Output
            } else {
                # Build output with non-zero components only
                $Output = "{0:N0}$DayLabel" -f $TimeSpan.Days
                if ($TimeSpan.Hours -gt 0) {
                    $Output += " {0:N0}$HourLabel" -f $TimeSpan.Hours
                }
                if ($TimeSpan.Minutes -gt 0) {
                    $Output += " {0:N0}$MinuteLabel" -f $TimeSpan.Minutes
                }
                if ($TimeSpan.Seconds -gt 0) {
                    $Output += " {0:N0}$SecondLabel" -f $TimeSpan.Seconds
                }
                $Output
            }
        }
    }

    # The actual prompt output with history ID, previous command duration, and current path.
    Write-Host "[$((Get-History)[-1].Id)] " -NoNewline -ForegroundColor Cyan
    Write-Host "$(Format-TimeSpan -TimeSpan ((Get-History)[-1].Duration) -Abbreviate) " -NoNewline -ForegroundColor Yellow
    Write-Host "$($PWD.ToString().Replace($HOME,'~'))" -ForegroundColor Cyan
    Write-Host '>' -NoNewline -ForegroundColor White
    return ' '
}
