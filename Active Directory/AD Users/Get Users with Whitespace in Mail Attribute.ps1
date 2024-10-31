$Pattern = '\s+'
$Users = Get-ADUser -Filter * -Properties mail | Where-Object { $_.mail -Match $Pattern }

If ($Users.count -gt 0) {
	$Users | Select-Object Name, mail | Export-Csv 'Accounts with Whitespace in Mail.csv' -NoTypeInformation
}
