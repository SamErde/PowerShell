<#
    .SYNOPSIS
    Run a complete set of DCDIAG tests on all DCs in the forest.

    .DESCRIPTION
    This script runs a standard set of DCDIAG tests against all DCs in the forest and saves the details to a time-stamped log file.
    It then lists all of the omitted tests that are noted in the log file and runs each one of those, saving a log file for each.

    .NOTES
    Requires ADDS management tools (dcdiag.exe, netdom.exe) which are installed with an ADDS role automatically or when adding the
    ADDS management tools feature to any computer. Minimizes dependencies by not requiring the ActiveDirectory PowerShell module.
    
    DCDIAG Reference: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc731968(v=ws.11)

    AUTHOR  : Sam Erde
    DATE    : 2021/06/30
    VERSION : 1.0
    CONTACT :
                https://github.com/SamErde
                https://twitter.com/SamErde
#>

$TimeStamp = Get-Date -Format "yyymmdd_hhmmss"
$LogFile = "dcdiag_$TimeStamp.log"

# Find the PDC FSMO role holder.
try {
    $PDCe = ( ( ( (& netdom query PDC) | 
        Select-String -Pattern "The command completed successfully." -Context 1 -SimpleMatch) -Split '\r?\n' ) | 
        Select-Object -Index 0).Trim()
}
catch {
    Write-Output "Failed to find a PDCe."
    $PDCe = $null
}

# Run DCDIAG agains all DCs in the enterprise [forest] (/e), with verbose output (/v), ignoring superfluous error messages (/i), writing to a log file (/f).
& dcdiag /s:$PDCe /e /v /i /f:$LogFile

# Find lines that note omitted tests and add each unique test name to an array
$OmittedTests = (Get-Content -Path $LogFile | Select-String -Pattern "Test omitted" -SimpleMatch | Select-Object -Unique) -Replace("      Test omitted by user request: ","")

foreach ($item in $OmittedTests) {
    $TestLogFile = 'dcdiag_'+$TimeStamp+'_'+$item+'.log'
    & dcdiag.exe /Test:$item /e /f:$TestLogFile
}
