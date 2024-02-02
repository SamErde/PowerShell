#Parts of this code borrowed from https://rcmtech.wordpress.com/2013/02/14/powershell-parallel-ping-test-with-csv-result-files/
Workflow PingTest{
ipconfig.exe /flushdns #Flush the DNS between each loop so it isn't using the cache to resolve each hostname's IP address.
$csvComputers = Import-Csv -Path ".\computers.csv" #Import the CSV.

    foreach -parallel ($Computer in $csvComputers){
        $Server = $Computer.Server
        $Time = Get-Date

        $TestResult = Test-Connection -ComputerName $Server -Count 1 -ErrorAction SilentlyContinue
            inlinescript{
                if ($using:TestResult.ResponseTime -eq $null){
                    $ResponseTime = -1
                    Send-MailMessage -SmtpServer "" -From "" -To "" -Subject "Ping Failure: $using:Server" -Body "Ping test has failed for $using:Server at $using:Time."

                } else {
                    $ResponseTime = $using:TestResult.ResponseTime
                }
                #$ResultObject = New-Object PSObject -Property @{Time = $using:Time; Computer = $using:Server; ResponseTime = $ResponseTime}
                #Export-Csv -InputObject $ResultObject ".\PingServers.csv" -Append -NoTypeInformation
            }
    }
}
Clear-Host
while($true){
    $Now = Get-Date
    Write-Host $Now "Testing..."
    PingTest
    Write-Host `n "Sleeping..." `n
    Start-Sleep 180
}
