<#
.SYNOPSIS

.DESCRIPTION

.NOTES

#>

#Update this list of servers or replace the statically generated array with a Get-ExchangeServer or Get-ADDomainController type of cmdlet.
$servers = @('', '', '')
$Creds = Get-Credential

if ($session) { Remove-PSSession $session }

#Loop through each server in the list, open a PowerShell remoting session, then show the name and status of the session. Skip (continue) to the next server if a connection fails.
foreach ($server in $servers) {
    $session = New-PSSession -ComputerName $server -Name $server -Credential $Creds

    Try {
        Write-Information "Connecting to $server... " -InformationAction Continue
        Enter-PSSession $session
    } Catch {
        Write-Warning "Failed to enter the PSSession for $server. Skipping." -WarningAction Continue
        Continue
    }
    Write-Output $session.State

    <#
        Code to be run on each remote server go here.
    #>
    Write-Information 'Inner code.' -InformationAction Continue

    #Cleanup and then show the current PSSession state.
    Exit-PSSession
    Remove-PSSession $session
    Write-Information "$session.ComputerName $session.State `n`n" -InformationAction Continue
}
