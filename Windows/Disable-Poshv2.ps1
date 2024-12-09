[CmdletBinding()]

$TimeStamp = Get-Date -f yyyy-MM-dd--HH-mm
Start-Transcript -Path ".\Disable-Poshv2 Transcript $TimeStamp.log"
$Logfile = ".\Disable-Poshv2 Retries $TimeStamp.log"
$LogfileFailures = ".\Disable-Poshv2 Failures $TimeStamp.log"

$ServerFailures = @()
$exclusions = @('', '', '')

#Filtering out production servers as well as any SQL, Exchange, SharePoint (SPS), Telephony, rinf* servers, and any servers in the "Non Windows" OU.
$servers = (Get-ADComputer -Filter 'OperatingSystem -like "Windows Server*" -and Enabled -eq "True" -and Name -notlike "*sps*"' `
        -SearchBase 'DC=DOMAIN,DC=COM' -SearchScope Subtree).Name | Where-Object { $_ -notin $Exclusions } | Sort-Object
Write-Information "$servers.Count servers found."

foreach ($server in $servers) {
    if (Test-WSMan -ComputerName $server -ErrorAction Ignore) {
        try {
            #If PowerShell version is higher than 2 and PowerShell-V2 InstallState is not 'Removed', then remove it through a remote session.
            Invoke-Command -ComputerName $server -ErrorAction Stop -ScriptBlock {
                if ( (Get-WindowsFeature PowerShell-V2).InstallState -ne 'Removed' -and ($PSVersionTable.PSVersion.Major) -gt 2 ) {
                    Remove-WindowsFeature PowerShell-V2 -Confirm:$false | Format-Table @{Name = 'Server'; Expression = { & hostname.exe } }, Success, ExitCode, RestartNeeded, FeatureResult
                }
            }
        } #try
        #The preceding if statement that tests WSMan connectivity will most likely preclude this catch statement from being encounterd.
        catch {
            Write-Warning "Trying to enable PS Remoting on $server."
            & psexec \\$server -s powershell.exe Enable-PSRemoting -Force > $null

            #If PowerShell version is higher than 2 and PowerShell-V2 InstallState is not 'Removed', then remove it through a remote session.
            Invoke-Command -ComputerName $server -ErrorAction Continue -ScriptBlock {
                if ( (Get-WindowsFeature PowerShell-V2).InstallState -ne 'Removed' -and ($PSVersionTable.PSVersion.Major) -gt 2 ) {
                    Remove-WindowsFeature PowerShell-V2 -Confirm:$false | Format-Table @{Name = 'Server'; Expression = { & hostname.exe } }, Success, ExitCode, RestartNeeded, FeatureResult
                }
            }
            $error[0] | Out-File $Logfile -Append
        } #catch
    } #if
    else {
        Write-Warning "Failed to connect to $server."
        $ServerFailures += $server
    } #else
    $ServerFailures | Out-File $LogfileFailures
} #foreach

if ($ServerFailures.Count -gt 0) {
    Write-Warning "Some servers failed. Please review $LogfileFailures."
}
Stop-Transcript
