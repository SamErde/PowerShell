function Get-ADSitesWithoutLinks {
    <#
    .SYNOPSIS
    Get all Active Directory sites that are not included in any site link.

    .DESCRIPTION
    Get-ADSitesWithoutLinks gets all Active Directory replication sites and site links, and then determines which sites are not included in any site link.

    .EXAMPLE
    Get-ADSitesWithoutLinks

    .EXAMPLE
    Get-AdSitesWithoutLinks | Format-Table @{Name = 'Site'; Expression = { $_.Key } }, @{Name = 'SiteLink[s]'; Expression = { $_.Value -join ', '}}

    Format the output as a table with custom headers.

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.0.1
    Modified: 2024-11-18
    #>
    [CmdletBinding()]
    param ( )

    begin { }

    process {
        # Create an ordered dictionary hash table from $ADSites that stores the site name as the key and the site object as the value.
        $ADSites = [ordered]@{}
        foreach ($site in (Get-ADReplicationSite -Filter * -Properties * -ErrorAction SilentlyContinue | Sort-Object -Property Name)) {
            $ADSites[$site.Name] = $site
        }

        $ADSiteLinks = Get-ADReplicationSiteLink -Filter * | Sort-Object -Property Name

        $SiteLinkMap = [ordered]@{}
        foreach ( $siteName in ($ADSites.GetEnumerator()).Name ) {

            foreach ($link in $ADSiteLinks) {
                foreach ($siteIncluded in $link.SitesIncluded) {
                    if ( (Get-ADReplicationSite $siteIncluded).Name -eq $siteName ) {
                        $SiteLinkMap[$SiteName] += "$($link).Name, " # need to remove the last comma and space from the last item
                    }
                }
            }
        }

        foreach ($siteLink in $SiteLinkMap.GetEnumerator()) {
            if ($null -eq $siteLink.Value) {
                Write-Warning -Message "The site $($siteLink.Key) is not found in any site link."
            }
        }
        #endregion Sites without SiteLinks
    }

    end {
        $SiteLinkMap
    }
}
