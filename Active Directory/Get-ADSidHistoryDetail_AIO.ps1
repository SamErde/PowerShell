function Get-TrustedDomainSIDMapping {
    <#
    .SYNOPSIS
    Get the SID and DNSRoot name of trusted domains and forests.

    .DESCRIPTION
    This function retrieves the SID and DNSRoot name of trusted domains and forests in the current Active Directory forest.

    .PARAMETER ManualEntry
    If specified, the user may manually provide a SID and DNS name to add to the list of trusted domains.

    .EXAMPLE
    $SIDMappingTable = Get-TrustedDomainSIDMapping -ManualEntry 'S-1-5-21-1234567890-1234567890-1234567890', 'example.com' -Verbose

    This example retrieves the SIDs and DNSRoot names of trusted domains and forests in the current Active Directory forest and adds a manual entry to the results.

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.0.1
    Modified: 2024-11-14

    To-Do:
    - Add support for trusted forests and external trusts.
    - Add support for manually including a CSV file with trusted domain information.
    - Add support for exporting a CSV file with trusted domain information.
    - Add support for taking an array of trusted domain SIDs and DNS root names as input for ManualEntry.

    .LINK
    https://github.com/SamErde

    .LINK
    https://linktr.ee/SamErde

    .LINK
    https://www.sentinel.com/
    #>
    [CmdletBinding()]
    param (
        # If specified, the user may manually provide a SID and DNS name to add to the list of trusted domains.
        [Parameter(HelpMessage = 'Enter the SID and DNS name of a trusted domain in the format ''S-1-5-21-1234567890-1234567890-1234567890'', ''example.com''.')]
        [array]$ManualEntry
    )

    begin {
        # Import the ActiveDirectory module if it is not already loaded.
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Verbose -Message 'Importing ActiveDirectory module.'
            Import-Module ActiveDirectory
            Write-Verbose -Message '------------------------------'
            Write-Verbose -Message 'Beginning to process trusts...'
        }

        # Create a dictionary to store domain SIDs with their corresponding DNS root names.
        $DomainSIDMapping = [ordered] @{}
        $CurrentDomain = (Get-ADDomain)
        $DomainSIDMapping.Add(
            $CurrentDomain.DomainSID.Value,
            $CurrentDomain.DNSRoot
        )

        # If the user provided a manual entry, add it to the dictionary.
        if ($PSBoundParameters.ContainsKey('ManualEntry')) {
            Write-Verbose -Message "Manually entered SID: $($ManualEntry[0])"
            Write-Verbose -Message "Manually entered DNS root name: $($ManualEntry[1])"
            $DomainSIDMapping.Add(
                $ManualEntry[0],
                $ManualEntry[1]
            )
        }

        $Trusts = Get-ADTrust -Filter *
    }

    process {
        # Loop through all trusts and add the trusted domain SIDs and DNS root names to the dictionary.
        foreach ($trust in $Trusts) {
            # Need to see if checking SID and DNSRoot requires a different process for trusted forests vs trusted domains.
            switch ($trust.TrustType) {
                <#
                "DomainTrust" {
                    Write-Verbose -Message "Processing domain trust: $($trust.Target)"
                    try {
                        Write-Verbose -Message "Processing trust: $($trust.Target)"
                        $TrustedDomain = Get-ADDomain -Identity $trust.Target
                        $DomainSIDMapping.Add(
                            $TrustedDomain.DomainSID.Value,
                            $TrustedDomain.DNSRoot
                        )
                    } catch {
                        Write-Warning -Message "$_"
                        continue
                    }
                }
                "ForestTrust" {
                    Write-Verbose -Message "Processing forest trust: $($trust.Target)"
                    # ... (add code to handle external trusts here
                }
                "External" {
                    Write-Verbose -Message "Processing external trust: $($trust.Target)"
                    # ... (add code to handle external trusts here
                }
                #>
                default {
                    try {
                        Write-Verbose -Message "Processing trust: $($trust.Target)"
                        $TrustedDomain = Get-ADDomain -Identity $trust.Target
                        $DomainSIDMapping.Add(
                            $TrustedDomain.DomainSID.Value,
                            $TrustedDomain.DNSRoot
                        )
                    } catch {
                        Write-Warning -Message "$_"
                        continue
                    }
                }
            } # end switch ($trust.TrustType)
        } # end foreach ($trust in $Trusts)
    } # end process

    end {
        $DomainSIDMapping
    } # end end
} # end function


function Get-AllAdSidHistorySourceDomains {
    <#
    .SYNOPSIS
    Get a list of source domains from all Active Directory objects that have SID history.

    .DESCRIPTION
    This function gets all Active Directory objects that have SID history and returns a list of source domain SIDs.

    .EXAMPLE
    Get-AllAdSidHistorySourceDomains

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.0.1
    Modified: 2024-11-14
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Verbose -Message 'Importing ActiveDirectory module.'
            Import-Module ActiveDirectory
            Write-Verbose -Message '------------------------------'
            Write-Verbose -Message "Beginning ${MyInvocation.InvocationName}..."
        }

        $DomainSIDs = New-Object -TypeName System.Collections.Generic.List[System.String]
    } # end begin

    process {
        # Get all ActiveDirectory objects that have SID history.
        $AllSIDHistory = Get-ADObject -Filter { SIDHistory -like '*' } -Properties SIDHistory | Select-Object -ExpandProperty SIDHistory

        foreach ($SID in $AllSIDHistory) {
            $DomainSIDs.Add($SID.Substring(0, $SID.LastIndexOf('-')))
        }
    } # end process

    end {

    } # end end

} # end function


function Get-AllADSIDHistoryDetails {
    [CmdletBinding()]
    [OutputType([hashtable])]
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
