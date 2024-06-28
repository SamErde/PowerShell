$Users = Get-ADUser -Filter * -Properties DoesNotRequirePreauth | Where-Object {$_.DoesNotRequirePreauth -eq $True}
$Users | Select-Object Name,SamAccountName,UserPrincipalName,DoesNotRequirePreauth | FT
$Users.Count

#Prevent accidental running before ready
break

# Turn off "DoesNotRequirePreauth" for all users.
Get-ADUser -Filter * | Set-ADAccountControl -DoesNotRequirePreauth $False
