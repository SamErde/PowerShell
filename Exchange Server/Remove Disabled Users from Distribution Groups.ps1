$Groups = Get-DistributionGroup -ResultSize Unlimited

foreach ($group in $Groups) {
    Write-Host -ForegroundColor Yellow "$group"
    Get-DistributionGroupMember $group | 
        ?{$_.RecipientType -like '*User*' -and $_.ResourceType -eq $null} | 
            Get-User | ?{$_.UserAccountControl -match 'AccountDisabled'} | 
                Remove-DistributionGroupMember $group -Confirm:$false
}