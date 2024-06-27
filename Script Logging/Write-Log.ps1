function Write-Log {
    # Write a string of text to the host and a log file simultaneously.
    [CmdletBinding()]
    [OutputType([string])]
        param (
            # The message to display and write to a log
            [Parameter(Mandatory)]
            [string]
            $LogText,

            # Type of output to send
            [Parameter()]
            [ValidateSet('Both','HostOnly','LogOnly')]
            [string]
            $Output = 'Both'
        )

        switch ($Output) {
            Both {
                Write-Host "$LogText"
                [void]$LogStringBuilder.AppendLine($LogText)
            }
            HostOnly {
                Write-Host "$LogText"
            }
            LogOnly {
                [void]$LogStringBuilder.AppendLine($LogText)
            }
        }
} # end function Write-Log
