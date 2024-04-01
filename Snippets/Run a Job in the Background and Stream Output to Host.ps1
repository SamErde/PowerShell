# Start a background job and stream its output to the host console
$job = Start-ThreadJob -ScriptBlock {
    Get-Process |
        ForEach-Object { Start-Sleep -ms 200; $_ } |
        oss | Write-Host
} -StreamingHost $Host