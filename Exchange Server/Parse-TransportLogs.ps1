<#
.SYNOPSIS
  Parses Exchange SMTP Transport logs and shows a summary of how many messages are sent by each IP/hostname. 
  Groups by message subject to help identify what applications or jobs might be sending the messages.

.DESCRIPTION
  Find out which machines are sending SMTP messages to your Exchange receive connectors.
  I like to pull SMTP transport logs from all Exchange Servers to a single local folder for parsing instead
  of running this against the live logs. Only reads in log entries that have the action "Queued" in the line, 
  because a single SMTP transaction can generate many lines in the logs.
.NOTES
  Credits : Initial concept was inspired by Chris Lehr's blog at 
  http://blog.chrislehr.com/2015/07/parse-transportlogs-which-ips-on-my.html
#>

Set-ExecutionPolicy RemoteSigned
$ExchangeCredential = Get-Credential -Message "Please enter credentials to connect to your Exchange Server. `nThis will be used to pull message subject lines from the tracking logs."
$ExchangeServer = Read-Host "Please specify an Exchange Server name."
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$ExchangeServer.mphealth.org/PowerShell/ -Authentication Kerberos -Credential $ExchangeCredential
Import-PSSession $ExchangeSession -DisableNameChecking

$SMTPLogPath = Read-Host "`nWhat is the path of the folder containing your SMTP transport logs?"
$Days = Read-Host "How many days of logs do you want to inspect? (24 hour spans from the current system time.) Enter 0 or blank to parse all logs in the folder."
Write-Output "Reading in source SMTP log files from $SMTPLogPath and parsing for queued messages being sent."
$FilteredLogs = (Select-String $SMTPLogPath\*.log -pattern "Queued").Line

$SMTPTransactions = ConvertFrom-Csv -InputObject $FilteredLogs -Header dt,connector,session,sequence-number,local,remote,event,data,context
  $SMTPTransactions | Add-Member -MemberType NoteProperty -Name "IPAddress" -Value ""
  $SMTPTransactions | Add-Member -MemberType NoteProperty -Name "Hostname" -Value ""
  $SMTPTransactions | Add-Member -MemberType NoteProperty -Name "MessageID" -Value ""
  $SMTPTransactions | Add-Member -MemberType NoteProperty -Name "Subject" -Value ""
  $SMTPTransactions | Add-Member -MemberType NoteProperty -Name "DateTime" -Value ""

    foreach ($item in $SMTPTransactions) {
      $item.DateTime = [DateTime]::Parse($item.dt)
      $item.IPAddress = $item.remote -replace '(.*):(.*)','$1'
    }

# Filter logs by the # of days chosen above, or parse all messages if the input is: zero, null, or an empty string.
switch ($Days) {
  { @(0, $null, "") -contains $_ } { $testSet = $SMTPTransactions }
  Default { $testSet = $SMTPTransactions | Where-Object { $_.DateTime -gt (Get-Date).AddDays(-$Days)} }
}

$testProgress = 0; $testCount = $testSet.Count
foreach ($item in $TestSet) {
  $testProgress++; $testPercent = [math]::Round(($testProgress/$testCount),2)*100
  Write-Progress -Activity "Parsing message $testProgress of $testCount." -Status "$testPercent% complete" -PercentComplete $testPercent

  $data = ($item.data.split("<")[1]).Split(">")[0]
  $subject = (Get-MessageTrackingLog -MessageId $data).MessageSubject | Select-Object -Unique
  $item.MessageID = $data
  $item.Subject = $subject
  $ErrorActionPreference = "SilentlyContinue" #To avoid ambiguous error output if/when a hostname is not found.
  $item.Hostname = ([System.Net.DNS]::GetHostbyAddress($item.IPAddress)).Hostname
  $ErrorActionPreference = "Continue"
}

Remove-PSSession $ExchangeSession.Id

Write-Output "Showing $Days days of results:"
$Summary = $TestSet | Group-Object -Property Hostname,IPAddress,Subject -NoElement | Sort-Object -Property @{Expression={$_.Count}; Descending=$true}, @{Expression={$_.Subject}; Descending=$true} -Unique
$Summary | Format-Table -AutoSize
