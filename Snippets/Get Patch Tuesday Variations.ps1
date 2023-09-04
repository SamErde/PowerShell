$FirstDayOfMonth = (Get-Date -Day 1).Date
$FirstDayOfMonth.AddDays( ([DayOfWeek]'Tuesday' - $FirstDayOfMonth.DayOfWeek + 7) % 7 + 7)
(0..16 | ForEach-Object {$FirstDayOfTheMonth.AddDays($_) } | Where-Object {$_.DayOfWeek -like "Tuesday"})[1]



$beginDate = (Get-Date -Day 1).Date
while ($beginDate.DayOfWeek -ne 'Tuesday') {
    $beginDate = $beginDate.AddDays(1)
}
$beginDate.AddDays(7)



if ($FirstDayOfMonth.DayOfWeek -gt [DayOfWeek]"Tuesday") {
    $Shift=[DayOfWeek]"Tuesday" + 7
}
else {
    $Shift=[DayOfWeek]"Tuesday"
}

$FirstDayOfMonth.AddDays($Shift - $FirstDayOfMonth.DayOfWeek)