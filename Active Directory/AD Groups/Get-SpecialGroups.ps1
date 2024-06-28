<#
    Here's a cool idea for a function:

    Get the members of well known security groups by their non-localized SIDs.

    Get count of members in tier-1 groups
    Check if user [x] is a member of any tier-1 groups
    Check if user [x] is in a specific tier-1 group or well-known group

#>
$PrincipalContext = [System.DirectoryServices.AccountManagement.PrincipalContext]::new('domain',$domain)
$DomainSID = [System.Security.Principal.SecurityIdentifier]::new($domain.GetDirectoryEntry().objectSid.Value,0)
$GroupSID = [System.Security.Principal.SecurityIdentifier]::new("$($DomainSID.Value)-516")
$GroupPrincipal = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($PrincipalContext,$GroupSID)
$DomainControllerCount.Group += $GroupPrincipal.GetMembers($true).count
