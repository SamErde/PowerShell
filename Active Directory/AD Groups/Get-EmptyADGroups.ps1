Import-Module ActiveDirectory
Get-ADGroup -Filter {GroupCategory -eq 'Security'} | Where-Object {@(Get-ADGroupMember $_).Length -eq 0}
