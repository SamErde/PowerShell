<#
.SYNOPSIS
    Quickly download a file using BITS.

.DESCRIPTION
    BITS can be used to speed up transfers, used as an alternative to Invoke-WebRequest,
    or used to provide resiliency when a download is interrupted.
#>

function Get-BITSDownload {
    [CmdletBinding()]
    param (

    )

    $url = 'http://files.net/test/file1.test'
    $output = "$PSScriptRoot\file1.test"
    $start_time = Get-Date

    Import-Module BitsTransfer

    Start-BitsTransfer -Source $url -Destination $output
    # OR
    Start-BitsTransfer -Source $url -Destination $output -Asynchronous

    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}
