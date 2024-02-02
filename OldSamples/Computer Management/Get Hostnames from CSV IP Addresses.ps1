# Import a CSV that should at least have a "SourceIP" column and a "Hostname" column.
$csv = ".\IPAddresses.csv"

# Import the CSV to a variable so we can update it and write the information back to the CSV at the end.
$IPAddressList = Import-Csv -Path $csv
# Using PowerShell 7's foreach-parallel. Should wrap this in a block that checks which version of PS is being used.
$IPAddressList | foreach-object {
    $ip = $_.SourceIP
    try {
        $_.Hostname = ([System.Net.Dns]::GetHostEntry($ip)).HostName
    }
    catch {
        Write-Error $error[0] #.Exception.Message.Split(':')[1]
    }
}
# Write the data back to the CSV with the hostnames added.
$IPAddressList | Export-Csv -Path $csv
