$file = ""
$csv = Import-Csv $file
foreach ($row in $csv) {
    $IP = $row.SourceIP
    $row.SourceName = ([System.Net.DNS]::GetHostEntry($IP)).Hostname
}
$csv | Export-Csv "results.csv" -NoTypeInformation
