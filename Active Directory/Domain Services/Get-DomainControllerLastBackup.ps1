# WIP

# Check the last backup date of Active Directory domain controllers
foreach ($DC in $ForestDomainControllers) {
    $BackupDate = Get-ADObject -Filter { ObjectClass -eq 'msDS-LastSuccessfulBackup' } -SearchBase "CN=NTDS Settings,CN=$($DC.Name),CN=Servers,CN=$($DC.Site),CN=Sites,CN=Configuration,$((Get-ADRootDSE).ConfigurationNamingContext)" -Property msDS-LastSuccessfulBackup | Select-Object -ExpandProperty msDS-LastSuccessfulBackup

    [PSCustomObject]@{
        Hostname       = $DC.HostName
        LastBackupDate = $BackupDate
    }
}
