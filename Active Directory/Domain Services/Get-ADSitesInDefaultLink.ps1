Import-Module ActiveDirectory
$sites = Get-ADReplicationSite -Filter *
foreach ($site in $sites) {
    $siteLinks = Get-ADReplicationSiteLink -Filter { SitesIncluded -match $($site.Name) }
    [PSCustomObject]@{
        SiteName  = $site.Name
        SiteLinks = $siteLinks.Name -join ', '
    }
}
Get-ADReplicationSiteLink -Filter 'SitesIncluded -contains "Default-First-Site-Name"' | Select-Object -ExpandProperty Name
