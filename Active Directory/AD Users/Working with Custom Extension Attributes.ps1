# To Do: Wrap in a function. Create a module to report on, set, or clear these.

# Check the usage of CustomAttribute[1-15] in Exchange Server:
$Recipients = Get-Recipient -Resultsize Unlimited
[System.Collections.ArrayList]$Report = @()
(1..15) | ForEach-Object {
    $CustomAttribute = "CustomAttribute$_"
    $Report.Add([PSCustomObject]@{
        Name      = $CustomAttribute
        Available = (($Recipients.Where({ [string]::IsNullOrEmpty($_.$CustomAttribute) }) ).Count)
        Used      = (($Recipients.Where({ -not [string]::IsNullOrEmpty($_.$CustomAttribute) }) ).Count)
        UsedBy    = $null # Optionally include the $Recipients that use this (not NullOrEmpty).
    }) | Out-Null
}
$Report

# Check the usage of ExtensionAttribute[1-15] in Active Directory. Optionally filter disable accounts.
$Users = Get-ADUser -Filter * -ResultsetSize 100000
[System.Collections.ArrayList]$Report = @()
(1..15) | ForEach-Object {
    $ExtensionAttribute = "ExtensionAttribute$_"
    $Report.Add([PSCustomObject]@{
        Name      = $ExtensionAttribute
        Available = (($Users.Where({ [string]::IsNullOrEmpty($_.$ExtensionAttribute) }) ).Count)
        Used      = (($Users.Where({ -not [string]::IsNullOrEmpty($_.$ExtensionAttribute) }) ).Count)
        UsedBy    = $null # Optionally include the $Users that use this (not NullOrEmpty).
    }) | Out-Null
}
$Report
