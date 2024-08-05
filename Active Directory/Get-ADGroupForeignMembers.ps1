function Get-AdGroupForeignMember {
    <#
        .SYNOPSIS
            Identify and list foreign security principals in an Active Directory group.

        .DESCRIPTION
            This function will check an Active Directory security group for names that are listed as SIDs.
            If a SID is found, the function will attempt to translate it to a human-readable name.
            If the translation fails, the SID will be listed as an orphaned foreign security principal.

        .PARAMETER Group
            The name of the group to check.

        .EXAMPLE
            Get-AdGroupForeignMembers -Group 'Domain Admins'
            This will check the 'Domain Admins' group for foreign security principals.

        .EXAMPLE
            $ForeignMembers = foreach ($group in $Groups) { Get-AdGroupForeignMembers $group }
            This will check an array of Groups for foreign security principals and return the results in an array.

        .OUTPUTS
            A list of custom objects containing the following properties:
            - Name: The name of the group member.
            - DN: The distinguished name of the group member.
            - Orphaned: A boolean indicating whether the group member is an orphaned foreign security principal.
            - Group: The distinguished name of the security group.
    #>

    [CmdletBinding()]
    param(
        # The name of the group to check
        [Parameter(Mandatory)]
        [string]$Group
    )

    Import-Module ActiveDirectory
    $Domain = Get-ADDomain -Current LocalComputer
    $DomainSID = $Domain.DomainSID.Value

    # Need to modify this to work in domains that do not have a GC domain controller.
    [string]$GlobalCatalog = (Get-ADDomainController -DomainName $Domain.DnsRoot -Discover -Service GlobalCatalog).HostName

    $TranslatedMembers = @()

    # Get members of the specified group
    $Members = (Get-ADGroup -Server $GlobalCatalog -Identity $Group -Properties member).member

    # Get the details of each member to identify foreign security principals
    foreach ($m in $Members) {
        $Name = ''
        $DN = $m.DistinguishedName
        $ADObject = Get-ADObject -Server $GlobalCatalog -Identity $($DN)
        $Orphan = $false

        # Find members with names listed as SIDs
        if ($ADObject.Name -match '^S-\d-\d-\d\d') {
            try {
                $Name = ([System.Security.Principal.SecurityIdentifier] $ADObject.Name).Translate([System.Security.Principal.NTAccount])
            } catch {
                $Name = $ADObject.Name
                $Orphan = $true
            }
        } else {
            $Name = $ADObject.Name
        }

        $TranslatedMembers += [PSCustomObject] @{
            Name     = $Name
            DN       = $($DN.Value)
            Orphaned = $Orphan
            Group    = $Group
        }
    }

    $TranslatedMembers
}
