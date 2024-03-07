<#
Stop Exchange Server maintenance, with recommended commands from Microsoft's KB at:
https://learn.microsoft.com/en-us/exchange/high-availability/manage-ha/manage-dags?view=exchserver-2019#performing-maintenance-on-dag-members
#>

$CurrentServer = "$env:computername"

# END MAINTENANCE
Set-ServerComponentState $CurrentServer -Component ServerWideOffline -State Active -Requester Maintenance
# Set-ServerComponentState $CurrentServer -Component UMCallRouter -State Active -Requester Maintenance
Set-Location $ExScripts
.\StopDagServerMaintenance.ps1 -serverName $CurrentServer
Set-ServerComponentState $CurrentServer -Component HubTransport -State Active -Requester Maintenance
Restart-Service MSExchangeTransport
Get-ServerComponentState $CurrentServer | Format-Table Component,State -Autosize
