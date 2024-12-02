Get-ADForestDomainControllerBackups {
    <#
    .SYNOPSIS
    Get the last backup date of Active Directory domain controllers in the forest.

    .DESCRIPTION
    Get-ADForestDomainControllerBackups retrieves the last successful backup date of each domain controller in the forest.

    .EXAMPLE
    Get-ADForestDomainControllerBackups
    Get the last backup date of all domain controllers in the forest.

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.0.1
    Modified: 2024-11-18
    #>
    [CmdletBinding()]
    param ()

    begin {
        $ForestDomainControllers = foreach ($domain in (Get-ADForest).domains) {
            Get-ADDomainController -Server $domain -Filter *
        }
    }
    process {
        foreach ($DC in $ForestDomainControllers) {
            $DCName = Get-ADObject -Identity $DC.NTDSSettingsObjectDN -Properties *
            $BackupTime = Get-ADObject -Identity $DCName -Properties BackupLastSuccessful
            if ($backupTime.BackupLastSuccessful) {
                "Last backup time for $($DC.Name): $($backupTime.BackupLastSuccessful)"
            } else {
                'No backup information available.'
            }
            #[PSCustomObject]@{
            #    Hostname = $DC.HostName
            #    LastBackupDate = $BackupDate
            #}
        }
    }
    end {}
}
