<#
    https://twitter.com/SamErde/status/1648023633913167875
#>

$FirstDayOfMonth = (Get-Date -Day 1).Date

# This one works but is too complex to understand. I don't even remember!
$PatchTuesday1 = $FirstDayOfMonth.AddDays( ([DayOfWeek]'Tuesday' - $FirstDayOfMonth.DayOfWeek + 7) % 7 + 7)

# This one checks the first 16 days of the month, grabs each instance of a Tuesday, and keeps the 2nd one (index of 1). Still weird and complex.
$PatchTuesday2 = (0..16 | ForEach-Object {$FirstDayOfMonth.AddDays($_) } | Where-Object {$_.DayOfWeek -like "Tuesday"})[1]

# This one from Mike F. Robbins is the most readable and understandable. It checks if the first Tuesday is in the first week, and if not, it adds 7 days to it.
while ($FirstDayOfMonth.DayOfWeek -ne 'Tuesday') {
    $FirstDayOfMonth = $FirstDayOfMonth.AddDays(1)
}
$FirstDayOfMonth.AddDays(7)


# This example from Kit @smallfoxx might make sense to some people and not others. It helps to step through it with debug to see the values as it runs.
if ($FirstDayOfMonth.DayOfWeek -gt [DayOfWeek]"Tuesday") {
    $Shift=[DayOfWeek]"Tuesday" + 7
}
else {
    $Shift=[DayOfWeek]"Tuesday"
}
$FirstDayOfMonth.AddDays($Shift - $FirstDayOfMonth.DayOfWeek)

# And here's one from Anthony J Fontanez (ajf8729) that forgoes complex logic for a longer, but simple switch statement.
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
$PatchTuesdaySwitch = (Get-Date -Day $Day).Date

# Here's a sample from James Orlando (@Jorlando82).
$FirstDay = (Get-Date).AddDays(-((Get-Date).AddDays(-1)).Day)
Switch ($FirstDay.DayOfWeek) {
    "Monday"   { $FirstDay.AddDays(8) }
    "Tuesday"  { $FirstDay.AddDays(7) }
    "Wednesday"{ $FirstDay.AddDays(13) }
    "Thursday" { $FirstDay.AddDays(12) }
    "Friday"   { $FirstDay.AddDays(11) }
    "Saturday" { $FirstDay.AddDays(10) }
    "Sunday"   { $FirstDay.AddDays(9) }
}

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
$PatchTuesdayFunction = PatchTuesday





<#
    -----
#>
$PatchTuesday
$PatchTuesday1
$PatchTuesday2
$PatchTuesdaySwitch
$PatchTuesdayFunction
