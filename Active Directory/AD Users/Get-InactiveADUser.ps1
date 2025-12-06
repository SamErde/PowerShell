function Get-InactiveADUser {
    <#
    .SYNOPSIS
        Find inactive enabled users in Active Directory based on logon activity.

    .DESCRIPTION
        This script queries Active Directory for user accounts and checks both the LastLogonDate (replicated) and
        LastLogon (non-replicated) attributes across all domain controllers to determine true inactivity. It also
        displays the last password change date for each user.

    .PARAMETER InactiveDays
        Number of days of inactivity to consider a user inactive. Default is 90 days.

    .PARAMETER IncludeDisabled
        Switch to include disabled accounts in the results.

    .PARAMETER CheckAllDCs
        Check the non-replication LastLogon user attribute on ALL domain controllers for extra validation of activity.

    .PARAMETER ExportCSV
    Optional path and filename to export results to a CSV file.

    .EXAMPLE
        Get-InactiveADUser -InactiveDays 60

        Finds users inactive for 60 or more days.

    .EXAMPLE
        Get-InactiveADUser -InactiveDays 90 -IncludeDisabled

        Finds all enabled and disabled users inactive for 90 or more days.

    .NOTES
        Author: Sam Erde
        Version: 1.1.2
        Requires: Active Directory PowerShell Module

        The lastLogonTimeStamp is replicated to all domain controllers and is accurate within ~14 days.

    .LINK
        https://learn.microsoft.com/en-us/services-hub/unified/health/remediation-steps-ad/regularly-check-for-and-remove-inactive-user-accounts-in-active-directory#context--best-practices

    #>

    [CmdletBinding()]
    [OutputType('Microsoft.ActiveDirectory.Management.ADUser')]
    Param(
        # The minimum number of days of inactivity to use as a cutoff for considering a user to be inactive.
        [Parameter(Mandatory = $false, HelpMessage = 'Minimum number of days of inactivity to use as the cutoff (1-3650).')]
        [ValidateRange(1, 3650)]
        [int]$InactiveDays = 90,

        # Include disabled accounts in the review of inactive users. By default, only enabled users are reviewed.
        [switch]$IncludeDisabled,

        # Check users' LastLogon timestamp on all domain controllers for extra confirmation.
        [switch]$CheckAllDCs,

        # Export the results to a CSV file.
        [string] $ExportCSV
    )

    # Requires the Active Directory module.
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Verbose 'Active Directory module imported successfully'
    } catch {
        Write-Error "Failed to import Active Directory module: $($_.Exception.Message)"
        return
    }

    $Results = [System.Collections.Generic.List[Microsoft.ActiveDirectory.Management.ADUser]]::new()

    $InactiveDate = (Get-Date).AddDays(-$InactiveDays)
    $DomainControllers = Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName

    Write-Host "Finding inactive users (inactive for $InactiveDays days or more)..." -ForegroundColor Cyan
    Write-Host "Checking all domain controllers for most recent logon times..." -ForegroundColor Cyan

    # Build filter for user query
    $Filter = { Enabled -eq $true -and LastLogonDate -lt $InactiveDate }
    if ($IncludeDisabled) {
        $Filter = "LastLogonDate -lt $InactiveDate"
    }

    # Get all Active Directory users
    $Users = Get-ADUser -Filter $Filter -Properties LastLogonDate, PasswordLastSet, Enabled, DistinguishedName, CanonicalName, CN | Sort-Object CanonicalName

    foreach ($User in $Users) {
        $MostRecentLogon = $null

        # Check LastLogonDate (replicated attribute)
        if ($User.LastLogonDate) {
            $MostRecentLogon = $User.LastLogonDate
        }

        if ($CheckAllDCs) {
            # Skip the check across all DCs if there is already a LastLogonDate within the past 14 days and if the most recent logon is more recent than the inactive date threshold.
            if ( $MostRecentLogon -lt (Get-Date).AddDays(-14) -and (-not $MostRecentLogon -lt $InactiveDate) ) {
                    # Check LastLogon (non-replicated) on every domain controller.
                    foreach ($DC in $DomainControllers) {
                        try {
                            $DCUser = Get-ADUser -Identity $User.SamAccountName -Server $DC -Properties LastLogon -ErrorAction Stop

                            if ($DCUser.LastLogon -gt 0) {
                                $LastLogonDC = [DateTime]::FromFileTime($DCUser.LastLogon)

                                if ($null -eq $MostRecentLogon -or $LastLogonDC -gt $MostRecentLogon) {
                                    $MostRecentLogon = $LastLogonDC
                                }
                            }
                        }
                        catch {
                            Write-Warning "Could not query $DC for user $($User.SamAccountName): $($_.Exception.Message)"
                        }
                    }
            }
        }

        # Determine if user is inactive by checking the most recent logon date.
        $IsInactive = $false
        if ($null -eq $MostRecentLogon) {
            $IsInactive = $true
        } elseIf ($MostRecentLogon -lt $InactiveDate) {
            $IsInactive = $true
        }
        $DaysInactive = if ($MostRecentLogon) { (New-TimeSpan -Start $MostRecentLogon -End (Get-Date)).Days } else { 'Never logged on' }

        # Add properties to the user object.
        $User | Add-Member -Force -MemberType NoteProperty -Name MostRecentLogon -Value $MostRecentLogon | Out-Null
        $User | Add-Member -Force -MemberType NoteProperty -Name IsInactive      -Value $IsInactive      | Out-Null
        $User | Add-Member -Force -MemberType NoteProperty -Name DaysInactive    -Value $DaysInactive    | Out-Null

        if ($IsInactive) {
            $Results.Add($User)
        }
    } # end foreach user

    # Display results
    if ($Results.Count -gt 0) {
        Write-Host "`nFound $($Results.Count) inactive user(s):" -ForegroundColor Yellow
        $Results | Format-Table CanonicalName, Enabled, MostRecentLogon, DaysInactive, PasswordLastSet -AutoSize | Out-Host

        # Optional: Export to CSV
        if ($PSBoundParameters.ContainsKey('ExportCSV')) {
            $ExportPath = ".\InactiveUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $Results | Export-Csv -Path $ExportPath -NoTypeInformation
            Write-Host "Results exported to: $ExportPath" -ForegroundColor Green
        }
    } else {
        Write-Host "`nNo inactive users found." -ForegroundColor Green
    }

    $Results
} # end Get-InactiveADUser
