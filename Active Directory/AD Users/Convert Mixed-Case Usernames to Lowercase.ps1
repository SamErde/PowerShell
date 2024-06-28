# Convert all mixed-case usernames to lowercase usernames:

$MixedCaseUserNames = Get-ADUser -Filter * | Where-Object {$_.samAccountName -cmatch "^(?=.*[a-z])(?=.*[A-Z]).*$" }

foreach ($user in $MixedCaseUserNames) {
    $AccountName = $user.SamAccountName.ToLower()
    $UPN = $user.UserPrincipalName.ToLower()

    Set-ADUser -Identity $user -SamAccountName $AccountName -UserPrincipalName $UPN -WhatIf
}
