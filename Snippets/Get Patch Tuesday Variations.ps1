<#
    .SYNOPSIS
        This script demonstrates several different ways to find Patch Tuesday (the 2nd Tuesday of the month).

    .DESCRIPTION
        This script demonstrates several different ways to find Patch Tuesday (the 2nd Tuesday of the month).
        It's a fun exercise to see how different people approach the same problem, and how some solutions are
        more readable and understandable than others--but beauty is in the eye of the beholder!
    
    .NOTES
        File Name      : Get Patch Tuesday Variations.ps1
        Author         : Sam Erde (@SamErde) and friends on Twitter/X

        Read the thread that inspired these examples at <https://twitter.com/SamErde/status/1648023633913167875>.
#>

# Find the first day of the moth
$FirstDayOfMonth = (Get-Date -Day 1).Date



# $PatchTuesday = # ...one of the following examples...



# This one works but is too complex to understand. I don't even remember how or why it works!
$PatchTuesday = $FirstDayOfMonth.AddDays( ([DayOfWeek]'Tuesday' - $FirstDayOfMonth.DayOfWeek + 7) % 7 + 7)
$PatchTuesday



# This one checks the first 16 days of the month, grabs each instance of a Tuesday, and keeps the 2nd one (index of 1). Still weird and complex.
$PatchTuesday = (0..16 | ForEach-Object {$FirstDayOfMonth.AddDays($_) } | Where-Object {$_.DayOfWeek -like "Tuesday"})[1]
$PatchTuesday



# This one from Mike F. Robbins is the most readable and understandable. It checks if the first Tuesday is in the first week, and if not, it adds 7 days to it.
$Day = $FirstDayOfMonth
while ($Day.DayOfWeek -ne 'Tuesday') {
    $Day = $Day.AddDays(1)
}
$PatchTuesday = $Day.AddDays(7)
$PatchTuesday



# And here's one from Anthony J Fontanez (@ajf8729) that forgoes complex logic for a simple "hard-coded" switch statement.
switch ( (Get-Date -Day 1).DayOfWeek ) {
    'Tuesday'   { 8 }
    'Monday'    { 9 }
    'Sunday'    { 10 }
    'Saturday'  { 11 }
    'Friday'    { 12 }
    'Thursday'  { 13 }
    'Wednesday' { 14 }
}
# I wrote the day into the date, et voila! Patch Tuesday.
switch ( (Get-Date -Day 1).DayOfWeek ) {
    'Tuesday'   { $Day = 8 }
    'Monday'    { $Day = 9 }
    'Sunday'    { $Day = 10 }
    'Saturday'  { $Day = 11 }
    'Friday'    { $Day = 12 }
    'Thursday'  { $Day = 13 }
    'Wednesday' { $Day = 14 }
}
$PatchTuesday = (Get-Date -Day $Day).Date
$PatchTuesday



# Here's a similar one from James Orlando (@Jorlando82) that also gets the 1st day of the month in a slightly different way.
$FirstDay = (Get-Date).AddDays(-((Get-Date).AddDays(-1)).Day)
$PatchTuesday = Switch ($FirstDay.DayOfWeek) {
    "Monday"   { $FirstDay.AddDays(8) }
    "Tuesday"  { $FirstDay.AddDays(7) }
    "Wednesday"{ $FirstDay.AddDays(13) }
    "Thursday" { $FirstDay.AddDays(12) }
    "Friday"   { $FirstDay.AddDays(11) }
    "Saturday" { $FirstDay.AddDays(10) }
    "Sunday"   { $FirstDay.AddDays(9) }
}
$PatchTuesday



# This example from Kit (@smallfoxx) works great but still challenges my ability to explain in a simple way.
if ($FirstDayOfMonth.DayOfWeek -gt [DayOfWeek]"Tuesday") {
    $Shift=[DayOfWeek]"Tuesday" + 7
}
else {
    $Shift=[DayOfWeek]"Tuesday"
}
# Use the shift to find the 1st Tuesday and then add 7 for the 2nd Tuesday.
$PatchTuesday = $FirstDayOfMonth.AddDays($Shift - $FirstDayOfMonth.DayOfWeek + 7)
$PatchTuesday



# Then kit (@smallfoxx) took it further and made it a function.
function WeekdayInMonth {
    param(
        [datetime]$Date = (Get-Date),
        [System.DayOfWeek]$Weekday = [System.DayOfWeek]::Tuesday,
        [int]$WeekNumber = 1
    )

    $FirstDay = $Date.AddDays(1 - $Date.Day)

    [int]$Shift = $WeekDay + 7 * $WeekNumber - $FirstDay.DayOfWeek

    if ($FirstDay.DayOfWeek -le $WeekDay) {
        $Shift -= 7
    }
    $FirstDay.AddDays($Shift)
}

function PatchTuesday {
    param(
        [datetime]$Date = (Get-Date)
    )

    WeekdayInMonth -Date $Date -Weekday [DayOfWeek]::Tuesday -WeekNumber 2
}
$PatchTuesday = PatchTuesday
