<#
.SYNOPSIS

.DESCRIPTION

.NOTES

#>

#Update this list of servers or replace the staticly generated array with a Get-ExchangeServer or Get-ADDomainController type of cmdlet.
$servers = @("","","")
$creds = Get-Credential

if ($session) { Remove-PSSession $session }

#Loop through each server in the list, open a PowerShell remoting session, then show the name and status of the session. Skip (continue) to the next server if a connection fails.
foreach ($server in $servers) {
    $session = New-PSSession -ComputerName $server -Name $server -Credential $creds

    Try { 
        Write-Host -ForegroundColor Green "Connecting to $server... " -NoNewline
        Enter-PSSession $session 
    } 
    Catch { 
        Write-Host -ForegroundColor DarkYellow "Failed to enter the PSSession for $server. Skipping."
        Continue 
    }
    Write-Output $session.State

    <#
        Code to be run on each remote server go here.
    #>
    Write-Host -ForegroundColor DarkGreen "Inner code."

    #Cleanup and then show the current PSSession state.
    Exit-PSSession
    Remove-PSSession $session
    Write-Host -ForegroundColor DarkYellow $session.ComputerName $session.State `n`n -NoNewline
}
