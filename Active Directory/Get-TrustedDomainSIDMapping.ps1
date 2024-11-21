function Get-TrustedDomainSIDMapping {
    <#
    .SYNOPSIS
    Get information about trusted/trusting domains in Active Directory.

    .DESCRIPTION
    This function retrieves the SID, DNSRoot name, and netBIOS name of trusted domains and forests in Active Directory. It returns this information as a dictionary object that can be used to easily reference domain details.

    .EXAMPLE
    $SIDMappingTable = Get-TrustedDomainSIDMapping

    Returns a dictionary object that contains the SID, DNSRoot name, and NetBIOS name of trusted domains and forests in Active Directory.

    .EXAMPLE
    Get-TrustedDomainSIDMapping | Format-Table @{N = 'NetBiosName'; E = { $_.TrustedDomainInformation.NetBIOSName } }, @{N = 'DomainSid'; E = { $_.TrustedDomainInformation.DomainSid } }, SourceName, TargetName

    Return a table that shows the NetBIOS name, Domain SID, and source/target names of all trusted domains in the forest.

    .INPUTS
    None

    .OUTPUTS
    System.Collections.Hashtable

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.1.0
    Modified: 2024-11-21

    .LINK
    https://github.com/SamErde

    .LINK
    https://linktr.ee/SamErde

    .LINK
    https://www.sentinel.com/
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param ()

    begin {
        # Create a dictionary to store domain SIDs with their corresponding DNS root names.
        $DomainSIDMapping = [ordered] @{}
    } # end begin

    process {
        # Get the details of all trusted domains and create a dictionary to lookup SID-based references and identify which domain they point to
        $ForestTrusts = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().GetAllTrustRelationships()
        $TrustedDomainInformation = $ForestTrusts.TrustedDomainInformation
        foreach ($domain in $TrustedDomainInformation) {
            $DomainSIDMapping[$domain.DomainSid] = $domain
        }
    } # end process

    end {
        $DomainSIDMapping
    } # end end

} # end function
