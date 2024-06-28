# List all foreign security principals in Active Directory that are a member of any group
$FSPContainer = $Domain.ForeignSecurityPrincipalsContainer
Get-ADObject -Filter 'ObjectClass -eq "foreignSecurityPrincipal"' -Properties 'msds-principalname','memberof' -SearchBase $FSPContainer -Server $GlobalCatalog | 
    Where-Object { $_.memberof -ne $null } | ForEach-Object {
        $AllForeignSecurityPrincipalMembers.Add($_)
    }
