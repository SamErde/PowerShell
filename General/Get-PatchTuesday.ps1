Function Get-PatchTuesday {
    <#
.SYNOPSIS
  Name: Get-PatchTuesday.ps1
  Return the date of Patch Tuesday for a given month, and provide functions for our management and monitoring products
  to be able to mute their alerts when a given device is scheduled for patching.

.DESCRIPTION
  Get the date of Patch Tuesday and the current internal patch week number.

  Functions in progress:
    1. Get the date of Patch Tuesday (Current month, last month, or next month), showing the current month by default.
    2. Get the current internal patch week (week 1...week 4).
    3. Get the patch date of a specific internal patch week (e.g. week 2 patching happens on Sunday, mm/dd/yyyy).

.NOTES
  Author: Sam Erde
    Date: 2021-03-11

.EXAMPLE
  Get the date of the current month's Patch Tuesday.
  Get-PatchTuesday

.EXAMPLE
  Get the date of the previous month's Patch Tuesday:
  Get-PatchTuesday -CheckMonth Previous

.EXAMPLE
  Get the date of the next month's Patch Tuesday:
  Get-PatchTuesday Next

#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $False)]
        [ValidateSet('Previous', 'Next', 'Current')]
        [string]$CheckMonth,

        [Parameter(Mandatory = $False)]
        [AllowEmptyString()]
        [ValidateSet('CurrentWeek', 'AllWeeks')]
        [string]$Output
    )

    $Today = (Get-Date 00:00:00)
    $ThisDay = $Today.DayOfWeek
    [datetime]$FirstDay = (Get-Date 00:00:00 -Day 1)
    [datetime]$NextFirstDay = (Get-Date 00:00:00 -Day 1).AddMonths(1)
    [datetime]$LastFirstDay = (Get-Date 00:00:00 -Day 1).AddMonths(-1)

    Switch ($CheckMonth) {
        'Previous' { $FirstDay = $FirstDay.AddMonths(-1) }
        'Next' { $FirstDay = $FirstDay.AddMonths(1) }
        'Current' { } # No change.
        Default { } # No change.
    }

    # Loop through the first 16 days of the specified month and select the second instance (index [1]) of a Tuesday.
    [datetime]$PatchTuesday = (( 0..16 | ForEach-Object { $FirstDay.AddDays($_) } | Where-Object { $_.DayOfWeek -like 'Tuesday' } )[1])
    [datetime]$NextPatchTuesday = (( 0..16 | ForEach-Object { $NextFirstDay.AddDays($_) } | Where-Object { $_.DayOfWeek -like 'Tuesday' } )[1])
    [datetime]$LastPatchTuesday = (( 0..16 | ForEach-Object { $LastFirstDay.AddDays($_) } | Where-Object { $_.DayOfWeek -like 'Tuesday' } )[1])

    ## Begin listing patch dates for the current and previous month.
    # Begin listing the month's Saturday and Sunday patch groups and set their start times at 21:00.
    $PatchWeeks = [ordered]@{
        'Week 1 Sunday'   = $PatchTuesday.AddDays(5).AddHours(21)
        'Week 2 Sunday'   = $PatchTuesday.AddDays(12).AddHours(21)
        'Week 3 Saturday' = $PatchTuesday.AddDays(18).AddHours(21)
        'Week 3 Sunday'   = $PatchTuesday.AddDays(19).AddHours(21)
        'Week 4 Saturday' = $PatchTuesday.AddDays(25).AddHours(21)
        'Week 4 Sunday'   = $PatchTuesday.AddDays(26).AddHours(21)
        # Week 5 will get evaulated next.
        'Week 5 Catchup'  = $null
    }
    # Check to see if a possible 5th patch week date comes before the next Patch Tuesday date.
    if ( $PatchTuesday.AddDays(33) -lt $NextPatchTuesday ) {
        $PatchWeeks.'Week 5 Catchup' = $PatchTuesday.AddDays(33)
    } else {
        $PatchWeeks.'Week 5 Catchup' = $null
    }
    # End listing of the month's Saturday and Sunday patch groups.
    # Begin listing the previous month's Saturday and Sunday patch groups and set their start times at 21:00.
    $PreviousPatchWeeks = [ordered]@{
        'Week 1 Sunday'   = $LastPatchTuesday.AddDays(5).AddHours(21)
        'Week 2 Sunday'   = $LastPatchTuesday.AddDays(12).AddHours(21)
        'Week 3 Saturday' = $LastPatchTuesday.AddDays(18).AddHours(21)
        'Week 3 Sunday'   = $LastPatchTuesday.AddDays(19).AddHours(21)
        'Week 4 Saturday' = $LastPatchTuesday.AddDays(25).AddHours(21)
        'Week 4 Sunday'   = $LastPatchTuesday.AddDays(26).AddHours(21)
        # Week 5 will get evaulated next.
        'Week 5 Catchup'  = $null
    }
    # Check to see if a possible 5th patch week date comes before the next Patch Tuesday date.
    if ( $LastPatchTuesday.AddDays(33) -lt $PatchTuesday ) {
        $PreviousPatchWeeks.'Week 5 Catchup' = $LastPatchTuesday.AddDays(33)
    } else {
        $PreviousPatchWeeks.'Week 5 Catchup' = $null
    }
    # End listing of the previous month's Saturday and Sunday patch groups.
    ## End listing of patch dates for the current and previous month.

    # List the upcoming patch weeks and find the next patch date.
    $UpcomingPatchWeeks = foreach ($key in ($PatchWeeks.GetEnumerator() | Where-Object { $_.Value -gt (Get-Date 21:00:00).AddHours(7) } )) { $key }
    $UpcomingPatchWeeks += @{'Next Week 1 Sunday' = $NextPatchTuesday.AddDays(5) }
    $NextPatchWeek = $UpcomingPatchWeeks[0]

    # Find the previous patch week date.
    # If the current date is less than the Week 1 patch date, then we need to find the last patch week date of the previous month.
    # Find the current patch week date.
    # Find the value between the previous patch week date and the next patch week date, but consider the last week to be current until 4 AM of the next Monday.

    ### Provide output as requested by the script's Output parameter, if specified.
    # Don't forget to RETURN what was asked for so other scripts can use it.
    If ($Output) {
        Switch ($Output) {
            $Output { $PatchWeeks.$Output } #Provide whichever patch week is requested.
            'Current' { Write-Output ($PatchWeeks.GetEnumerator() | Where-Object { $_.Value -eq $NextPatchDate }).Name }
            'All' { $PatchWeeks }
            Default { $PatchWeeks }         #Show all patch dates.
        }
    } Else {
        Write-Output "`nThis month's patch Tuesday is on $PatchTuesday and the patch schedule is: " $PatchWeeks
    }

} # End of Script
