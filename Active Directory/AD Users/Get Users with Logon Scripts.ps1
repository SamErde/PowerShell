# Get all Active Directory users that have a logon script defined
Get-ADUser -Filter 'ScriptPath -eq "*"'
