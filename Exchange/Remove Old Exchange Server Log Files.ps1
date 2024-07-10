<#
.SYNOPSIS
    A script to clear old Exchange logs files.
.DESCRIPTION
    This script will clear all Exchange Server log files under the installation's "Logging" path that are older than a set
    number of days. (It will not touch database log files unless those are intentionally put in the worst possible location!)
#>

# Set the number of days to preserve logs from.
$LogAgeDays = 14

# Check for the existince of the Exchange logging folder under the install path.
if (Test-Path -Path "$env:ExchangeInstallPath\Logging") {
    Set-Location -Path "$env:ExchangeInstallPath\Logging" -ErrorAction Stop

    # Get Exchang Server logs that are older than [nn] days and remove them. Any log files still in use will not be deleted.
    Get-ChildItem -Path "$env:ExchangeInstallPath\Logging" -Recurse -Include *.log | `
            Where-Object { $_.LastWriteTime -lt ((Get-Date).AddDays(-$LogAgeDays)) } | `
                Remove-Item -Confirm:$false -ErrorAction SilentlyContinue
}
