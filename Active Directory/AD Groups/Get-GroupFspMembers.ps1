function Get-GroupFspMembers {
    <#
    .SYNOPSIS
        Check Active Directory groups for members that are foreign security principals from other domains or forests.
    #>
    #Requires -Modules 'ActiveDirectory'

    Import-Module ActiveDirectory
    $Domain = Get-ADDomain -Current LocalComputer
    $DomainSID = $Domain.DomainSID.Value
    # Using a global catalog may be required for some queries to be comprehensive, but need to update to
    # handle child domains that do not have a global catalog.
    # [string]$DomainController = (Get-ADDomainController -DomainName $Domain.DnsRoot -Discover).HostName

    # Get all groups that are capable of containing foreign security principals. Ignore empty groups and global groups, which cannot contain members from other domains or forests.
    $Groups = Get-ADGroup -Properties members, Description -Filter 'GroupCategory -eq "Security" -and (GroupScope -eq "Universal" -or GroupScope -eq "DomainLocal") -and Members -like "*"'

    $GroupsWithForeignMembers = New-Object System.Collections.Generic.List[System.Object]

    foreach ($group in $Groups) {
        $FspMembers = $group.members | Where-Object { $_ -like "CN=S-1-*" -and $_ -notlike "$DomainSID*" }
        if ($FspMembers.count -ne 0) {
            $tempgroup = New-Object -TypeName PSObject
                $tempgroup | Add-Member -MemberType NoteProperty -Name 'GroupDN' -Value $group.distinguishedName
                $tempgroup | Add-Member -MemberType NoteProperty -Name 'Description' -Value $group.Description
                $tempgroup | Add-Member -MemberType NoteProperty -Name 'FspMembers' -Value ($FspMembers -join (', '))
            $GroupsWithForeignMembers.Add($tempgroup)
        }
    }
    $GroupsWithForeignMembers
}
