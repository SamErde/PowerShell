Connect-MgGraph
# Find duplicate devices by pulling all and grouping by DisplayName, then only keep a list where there are more than one entries with the same display name.
$DuplicateDevices = Get-MgDevice -All | Group-Object DisplayName | Where-Object {$_.Count -gt 1 -and $_.OperatingSystem -eq "Windows"} | Sort-Object Count

foreach ($group in $DuplicateDevices) {
    # For each group of duplicate DisplayName,
    # Expand the group object and sort it by the approximate last sign-in timestamp,
    # Then exclude the most recently active one so it is kept when the rest are removed.
    $OldDuplicates = $group | Select-Object -ExpandProperty Group | Sort-Object ApproximateLastSigninDateTime | Select-Object -SkipLast 1
    # Having excluded the most recent object, remove each "old" duplicate device in the group.
    $OldDuplicates | ForEach-Object { Remove-MgDevice -DeviceId $_.Id }
}
