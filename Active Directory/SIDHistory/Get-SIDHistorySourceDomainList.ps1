function Get-ADObjectWithSIDHistory {
    <#
    .SYNOPSIS
    Get a list of source domain SIDs from all Active Directory objects that have SID history.

    .DESCRIPTION
    This function gets all Active Directory objects that have SID history and returns a list of unique source domain SIDs.

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.1.0
    Modified: 2025-01-10
    #>
    [CmdletBinding()]
    [OutputType('Microsoft.ActiveDirectory.Management.ADObject[]')]
    param (
        <#
        # Type of objects to get. Default is 'All'.
        [Parameter()]
        [ValidateSet('All', 'User', 'Computer', 'Group')]
        [string]
        $Type = 'All'
        #>
    )

    begin {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Verbose -Message 'Importing ActiveDirectory module.'
            Import-Module ActiveDirectory
            Write-Verbose -Message '------------------------------'
            Write-Verbose -Message "Beginning ${MyInvocation.InvocationName}..."
        }

        <# Build the filter for the Get-ADObject cmdlet.
        $BaseFilter = 'SIDHistory -like "*"'
        switch ($Type) {
            'User' { $Filter = "$BaseFilter -and objectClass -eq 'user'" }
            'Computer' { $Filter = "$BaseFilter -and objectClass -eq 'computer'" }
            'Group' { $Filter = "$BaseFilter -and objectClass -eq 'group'" }
            'All' { $Filter = $BaseFilter }
        }
        #>
        $SIDHistorySourceDomainSIDList = [ordered]@{}
    } # end begin

    process {
        # Get all ActiveDirectory objects that have SID history.
        [Microsoft.ActiveDirectory.Management.ADObject[]]$ADObjectList = Get-ADObject -Filter $Filter -Properties SIDHistory | Select-Object * -ExpandProperty SIDHistory

        foreach ($ADObject in $ADObjectList) {

            foreach ($SIDHistoryEntry in $ADObject.SIDHistory) {
                # Extract the source domain SID from the SIDHistory attribute.
                $SourceDomainSID = $SIDHistoryEntry.Substring(0, $SIDHistoryEntry.LastIndexOf('-'))

                # Add the source domain SID to the list if it doesn't already exist.
                if (-not $SIDHistorySourceDomainSIDList.ContainsKey($SourceDomainSID)) {
                    $SIDHistorySourceDomainSIDList.Add($SourceDomainSID, $SourceDomainSID)
                }
            } # end foreach SIDHistoryEntry

        } # end foreach ADObject
    } # end process

    end {
        # Update to return the hash table after resolving source domain SIDs.
        $SIDHistorySourceDomainSIDList.Keys
    } # end end

} # end function
