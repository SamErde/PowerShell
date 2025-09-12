function Get-InactiveUsers {
    <#
.SYNOPSIS
    Lists inactive Active Directory users based on last logon timestamp information.

.DESCRIPTION
    The script queries Active Directory for the 'lastLogonTimeStamp' attribute of enabled user accounts. This replicated
    attribute provides sufficient accuracy for inactive user detection while offering much better performance than
    querying all domain controllers. Accounts with no logon after the defined threshold are reported as inactive. Users
    who have never logged on are included if their account creation date is older than the DaysInactive threshold.

.PARAMETER DaysInactive
    Number of days of inactivity used to identify an inactive user. Also used as the threshold for including never-
    logged-on users (if their account was created more than this many days ago).

.PARAMETER ExcludeNeverLoggedOn
    Exclude users who have never logged on from the results, even if their account creation date exceeds the threshold.

.PARAMETER PassThru
    Return the inactive user objects to the pipeline instead of displaying formatted output. Useful for further processing
    or assignment to variables.

.PARAMETER ExportPath
    Optional path and filename to export results to a CSV file.

.EXAMPLE
    Get-InactiveUsers -DaysInactive 90
    Returns users who haven't logged on in 90+ days, plus never-logged-on users created 90+ days ago.

.EXAMPLE
    Get-InactiveUsers -DaysInactive 30 -ExportPath "C:\Reports\InactiveUsers.csv"
    Returns users who haven't logged on in 30+ days, plus never-logged-on users created 30+ days ago.
    Exports results to CSV and uses 30-day threshold.

.EXAMPLE
    Get-InactiveUsers -DaysInactive 60 -ExcludeNeverLoggedOn
    Returns only users who logged on but haven't logged on in 60+ days (excludes never-logged-on users).

.EXAMPLE
    $InactiveUsers = Get-InactiveUsers -DaysInactive 30 -PassThru
    Gets inactive users and stores them in a variable for further processing without displaying formatted output.

.NOTES
    Author: Sam Erde
    Version: 1.1
    Requires: Active Directory PowerShell Module

    Uses lastLogonTimeStamp for faster execution (accurate within ~14 days)

.LINK
    https://learn.microsoft.com/en-us/services-hub/unified/health/remediation-steps-ad/regularly-check-for-and-remove-inactive-user-accounts-in-active-directory#context--best-practices
#>

    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = 'Number of days of inactivity to use as the cutoff (1-3650).')]
        [ValidateRange(1, 3650)]
        [int] $DaysInactive = 90,

        [Parameter(HelpMessage = 'Path to export results to CSV.')]
        [string] $ExportPath,

        [Parameter(HelpMessage = 'Exclude users who have never logged on from the results.')]
        [switch] $ExcludeNeverLoggedOn,

        [Parameter(HelpMessage = 'Return objects to the pipeline instead of displaying formatted output.')]
        [switch] $PassThru
    )

    # Requires the Active Directory module.
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Verbose 'Active Directory module imported successfully'
    } catch {
        Write-Error "Failed to import Active Directory module: $($_.Exception.Message)"
        break 1
    }

    # Calculate the cutoff date and its file time representation for the AD filter.
    [datetime]$CutoffDate = (Get-Date).AddDays(-$DaysInactive)
    [long]$CutoffFileTime = $CutoffDate.ToFileTime()

    Write-Host "Searching for users inactive since: $($CutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))." -ForegroundColor Cyan
    Write-Host 'Using lastLogonTimeStamp for better performance (precise to within ~14 days).' -ForegroundColor Yellow

    # Build the server-side filter for Get-ADUser.
    # This is more efficient as it filters objects on the domain controller.
    $Filter = "Enabled -eq 'True' -and (lastLogonTimeStamp -lt '$CutoffFileTime' -and lastLogonTimeStamp -ne 0)"

    if (-not $ExcludeNeverLoggedOn) {
        $Filter += " -or (lastLogonTimeStamp -notlike '*' -and whenCreated -lt '$CutoffDate')"
        Write-Host 'Including never-logged-on users created before the cutoff date.' -ForegroundColor Yellow
    }

    # Get user accounts matching the optimized filter.
    Write-Host 'Retrieving inactive user accounts...' -ForegroundColor Yellow
    try {
        $InactiveUsersResult = Get-ADUser -Filter $Filter -Properties samAccountName, DisplayName, lastLogonTimeStamp, whenCreated, DistinguishedName -ErrorAction Stop
        Write-Host "Found $($InactiveUsersResult.Count) inactive user account(s)." -ForegroundColor Green
    } catch {
        Write-Error "Failed to get user accounts: $($_.Exception.Message)"
        break 1
    }

    $InactiveUsers = @()
    [Int16] $UserCount = 0

    foreach ($User in $InactiveUsersResult) {
        $UserCount++
        $PercentComplete = [math]::Round(($UserCount / $InactiveUsersResult.Count) * 100, 1)
        Write-Progress -Activity 'Processing user data' -Status "Processing $($User.SamAccountName) ($UserCount of $($InactiveUsersResult.Count))" -PercentComplete $PercentComplete

        # Reset blank defaults before adding a user to the results.
        $LastLogonTimeStamp = $User.lastLogonTimeStamp
        $LastLogonDate = $null
        $Status = ''

        if ($null -eq $LastLogonTimeStamp -or $LastLogonTimeStamp -eq 0) {
            $Status = 'Never logged on'
        } else {
            $LastLogonDate = [DateTime]::FromFileTime($LastLogonTimeStamp)
            $Status = 'Inactive'
        }

        # Calculate days since last logon
        $DaysSinceLogon = if ($LastLogonDate) {
            [math]::Round((New-TimeSpan -Start $LastLogonDate -End (Get-Date)).TotalDays)
        } else {
            $null
        }

        $InactiveUsers += [PSCustomObject]@{
            SamAccountName    = $User.SamAccountName
            DisplayName       = $User.DisplayName
            LastLogonDate     = $LastLogonDate
            DaysSinceLogon    = $DaysSinceLogon
            Status            = $Status
            WhenCreated       = $User.whenCreated
            DaysSinceCreated  = [math]::Round((New-TimeSpan -Start $User.whenCreated -End (Get-Date)).TotalDays)
            DistinguishedName = $User.DistinguishedName
        }
    }

    Write-Progress -Activity 'Processing user data.' -Completed

    # Process results
    if ($InactiveUsers.Count -gt 0) {
        # Sort once for all operations
        $SortedInactiveUsers = $InactiveUsers | Sort-Object LastLogonDate

        # Handle PassThru parameter
        if ($PassThru) {
            # Return objects to pipeline and suppress other output
            Write-Verbose "Found $($InactiveUsers.Count) inactive user(s) - returning objects to pipeline"

            # Export to CSV if requested (silent operation with PassThru)
            if ($ExportPath) {
                try {
                    $SortedInactiveUsers | Export-Csv -Path $ExportPath -NoTypeInformation -ErrorAction Stop
                    Write-Verbose "Results exported to: $ExportPath"
                } catch {
                    Write-Error "Failed to export results: $($_.Exception.Message)"
                }
            }

            # Return sorted objects to pipeline
            $SortedInactiveUsers
        } else {
            # Normal display mode
            Write-Host "`nFound $($InactiveUsers.Count) inactive user(s):" -ForegroundColor Red

            # Display formatted table
            $SortedInactiveUsers | Format-Table -AutoSize -Property SamAccountName, DisplayName, LastLogonDate, DaysSinceLogon, DaysSinceCreated

            # Export to CSV if requested
            if ($ExportPath) {
                try {
                    $SortedInactiveUsers | Export-Csv -Path $ExportPath -NoTypeInformation -ErrorAction Stop
                    Write-Host "Results exported to: $ExportPath" -ForegroundColor Green
                } catch {
                    Write-Error "Failed to export results: $($_.Exception.Message)"
                }
            }

            # Summary statistics
            $NeverLoggedOn = ($InactiveUsers | Where-Object { $_.Status -eq 'Never logged on' }).Count
            $InactiveCount = ($InactiveUsers | Where-Object { $_.Status -eq 'Inactive' }).Count

            Write-Host "`nSummary:" -ForegroundColor Cyan
            Write-Host "  Total inactive users: $($InactiveUsers.Count)" -ForegroundColor White
            Write-Host "  Never logged on: $NeverLoggedOn" -ForegroundColor White
            Write-Host "  Inactive (logged on before cutoff): $InactiveCount" -ForegroundColor White
            Write-Host "  Cutoff date: $($CutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        }
    } else {
        if ($PassThru) {
            # Return empty array for consistency
            Write-Verbose 'No inactive users found - returning empty array'
            return @()
        } else {
            Write-Host "`nNo inactive users found matching the specified criteria." -ForegroundColor Green
            Write-Host "Cutoff date: $($CutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
        }
    }

}
