# Some basic Exchange Server checks to run after maintenance.
Write-Host -ForeGroundColor Yellow "Service Health"
Test-ServiceHealth
Write-Host -ForeGroundColor Yellow "MAPI Connectivity"
Test-MAPIConnectivity
Write-Host -ForeGroundColor Yellow "Mailbox Database Copy Status"
Get-MailboxDatabaseCopyStatus
Write-Host -ForeGroundColor Yellow "Cluster Node Status"
Get-ClusterNode
Write-Host -ForeGroundColor Yellow "Replication Health"
Test-ReplicationHealth
Write-Host -ForeGroundColor Yellow "Server Component State"
Get-ServerComponentState -Identity $env:COMPUTERNAME
