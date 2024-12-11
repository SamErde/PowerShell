<#
.SYNOPSIS
Loop through a list of specified domain controllers, and then loop through all DNS Server zones on each domain
controller to make desired changes.

.DESCRIPTION
This script was written to change the Secondary Servers setting and the SecureSecondaries setting on all DNS zones on
all DNS Servers (all domain controllers, in our environment.) It provides an ideal way to adjust settings for one (or
all) zones across every zone server, because some settings are stored individually in each server's registry, and not
completed replicated, even when the zone is AD-integrated.

Our servers actually have Remote Registry access disabled, so the remote part of this script will not work, but the
inner loop beginning with the collection of zones ("$zones = Get-ChildItem ...") from the registry can be run manually
on each DNS Server, still saving time and providing more accuracy than multiple manual changes could.

.NOTES
Be sure to test your changes first by using -WhatIf on the Set-ItemProperty cmdlets, and also by testing your changes
manually with at least one zone. Check the registry and the GUI after running your script, and note that changing some
zone settings via the registry will require the DNS Server service to be restarted in order for those changes to be read
and take effect.
#>

if ($session) { Remove-PSSession $session }

#Specify a list of DNS servers manually, or just get a list of all domain controllers in the domain.
#$servers = @("","","","","")
$servers = Get-ADDomainController -Filter * | Select-Object Hostname
$Creds = Get-Credential
#Loop through each server in the list, opening a PowerShell remoting session, then show the name and status of the session. Skips (continue) to the next server if a connection fails.
foreach ($srv in $servers) {
    $server = $srv.Hostname
    $session = New-PSSession -ComputerName $server -Name $server -Credential $Creds
    Try {
        Write-Host -ForegroundColor Green "Connecting to $server... " -NoNewline
        Enter-PSSession $session
    } Catch {
        Write-Host -ForegroundColor DarkYellow "Failed to enter the PSSession for $server. Skipping."
        Continue
    }
    Write-Output $session.State

    $zones = Get-ChildItem -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\DNS Server\Zones\'

    foreach ($zone in $zones) {
        Write-Host "`n`n 'Name: ' (Get-ItemProperty -PSPath $zone.PSPath).PSChildName" -NoNewline -ForegroundColor Yellow
        Write-Host "`n 'SecondaryServers: ' (Get-ItemProperty -PSPath $zone.PSPath).SecondaryServers" -NoNewline
        Write-Host "`n 'SecureSecondaries: ' (Get-ItemProperty -PSPath $zone.PSPath).SecureSecondaries `n" -NoNewline

        #Set-ItemProperty -PSPath $zone.PSPath -Name "SecondaryServers" -Value "" -WhatIf
        #Set-ItemProperty -PSPath $zone.PSPath -Name "SecureSecondaries" -Value "3" -WhatIf
    }

    #Cleanup and then show the current PSSession state.
    if ($session) { Exit-PSSession }
    if ($session) { Remove-PSSession $session }
    Write-Host -ForegroundColor DarkYellow $session.ComputerName $session.State `n`n -NoNewline
}
