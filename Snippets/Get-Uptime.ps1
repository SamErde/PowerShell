function Get-Uptime {
    <#
    .SYNOPSIS
        Get the current system uptime.
    .DESCRIPTION
        Return the current system uptime in your desired unit of measurement.
    .PARAMETER Units
        Specify the units of time to return system uptime in.
        Accepted values: 'Days','Hours','Minutes','Seconds','Milliseconds','Microseconds','Nanoseconds'
    .EXAMPLE
        Get-Uptime -Units Seconds
    .Example
        Get-Uptime
    .NOTES
        Inspired by @md's blog at https://xkln.net/blog/getting-uptime-with-powershell---the-fast-way/
    #>
    [Cmdletbinding()]
    [Alias("Uptime")]
    param (
        # The type of units to return
        [Parameter()]
        [ValidateSet('Days','Hours','Minutes','Seconds','Milliseconds','Microseconds','Nanoseconds')]
        [string]
        $Units
    )
    if ( $Units ) {
        [TimeSpan]::FromTicks([System.Diagnostics.Stopwatch]::GetTimestamp()).$("Total$Units")
    } else {
        [TimeSpan]::FromTicks([System.Diagnostics.Stopwatch]::GetTimestamp()).ToString("d' Days 'h' Hours 'm' Minutes 's' Seconds'")
    }
}
