$Groups = Get-DistributionGroup -ResultSize Unlimited

foreach ($group in $Groups) {
    Write-Information "$group"
    Get-DistributionGroupMember $group |
        Where-Object { $_.RecipientType -like '*User*' -and $_.ResourceType -eq $null } |
            Get-User | Where-Object { $_.UserAccountControl -match 'AccountDisabled' } |
                Remove-DistributionGroupMember $group -Confirm:$false
}
