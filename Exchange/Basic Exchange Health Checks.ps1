# Some basic Exchange Server checks to run after maintenance.
Write-Information "Service Health"
Test-ServiceHealth
Write-Information "MAPI Connectivity"
Test-MAPIConnectivity
Write-Information "Mailbox Database Copy Status"
Get-MailboxDatabaseCopyStatus
Write-Information "Cluster Node Status"
Get-ClusterNode
Write-Information "Replication Health"
Test-ReplicationHealth
Write-Information "Server Component State"
Get-ServerComponentState -Identity $env:COMPUTERNAME
