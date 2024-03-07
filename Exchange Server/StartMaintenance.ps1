<#
Start Exchange Server maintenance, with recommended commands from Microsoft's KB at:
https://learn.microsoft.com/en-us/exchange/high-availability/manage-ha/manage-dags?view=exchserver-2019#performing-maintenance-on-dag-members
#>

$CurrentServer = "$env:computername"
# Get a random number between 1 and [the count of servers in the DAG].
$Random = Get-Random -Maximum ( (Get-DatabaseAvailabilityGroup).Servers.Name.Count ) -Minimum 1

# Select a random server name from the list of servers in the DAG, excluding the current server's name.
# Subtract 1 to account for the array index starting at 0 instead of 1.
# Depends on the ActiveDirectory PowerShell module to get the FQDN.
$AlternateServer = ((Get-DatabaseAvailabilityGroup).Servers).Where({$_.Name -ne $CurrentServer}).Name | Select-Object -Index ($Random -1)
$AlternateServerFQDN = "$AlternateServer.$((Get-ADDomain).DNSRoot)"

# ===== BEGIN MAINTENANCE =====

# Drain the transport queues
Set-ServerComponentState $CurrentServer -Component HubTransport -State Draining -Requester Maintenance
Restart-Service MSExchangeTransport
# Drain the UM call queue if that service is in use.
# Set-ServerComponentState $CurrentServer -Component UMCallRouter -State Draining -Requester Maintenance
Set-Location -Path $ExScripts
# Start DAG server maintenance.
.\StartDagServerMaintenance.ps1 -ServerName $CurrentServer -MoveComment Maintenance -PauseClusterNode
# Rediret messages to a random alternate server in the DAG.
Redirect-Message -Server $CurrentServer -Target $AlternateServerFQDN
# Set all server components offline for maintenance.
Set-ServerComponentState $CurrentServer -Component ServerWideOffline -State Inactive -Requester Maintenance