function Get-AllADSIDHistoryDetails {
    [CmdletBinding()]
    param ()

    begin {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Verbose -Message 'Importing ActiveDirectory module.'
            Import-Module ActiveDirectory
            Write-Verbose -Message '------------------------------'
            Write-Verbose -Message "Beginning ${MyInvocation.InvocationName}..."
        }

        $DomainSIDMapping = Get-TrustedDomainSIDMapping
        $SourceDomainAssociatedObjects = @{}
    } # end begin

    process {
        # Get all Active Directory objects that have a value in SID history.
        $ADObjectsWithSIDHistory = Get-ADObject -Filter 'SIDHistory -like "*"' -Properties SIDHistory

        # Loop through each ADObject and loop through each SID history item on that object.
        # For each SID history item, remove the RID and add the domain SID to the $SourceDomains hash table.
        foreach ($ADObject in $ADObjectsWithSIDHistory) {
            foreach ($SIDHistory in $ADObject.SIDHistory) {
                $DomainSID = $SIDHistory.Substring(0, $SIDHistory.LastIndexOf('-'))
                # If the domain SID is in the $DomainSIDMapping hash table, use the domain name as the key. If not, use the DomainSID as the key in the $SourceDomains hash table.
                $Domain = if ($DomainSIDMapping[$DomainSID]) {
                    $DomainSIDMapping[$DomainSID].Value
                } else {
                    $DomainSID
                }
                # Add the domain name as the key and the ADObject as the value to the $SourceDomainAssociatedObjects hash table.
                $SourceDomainAssociatedObjects.Add(
                    $Domain,
                    ([System.Collections.Generic.List[object]]).Add($ADObject)
                )
            }
        }
    } # end process

    end {
        $SourceDomainAssociatedObjects
    }
}
