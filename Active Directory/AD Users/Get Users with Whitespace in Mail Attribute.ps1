function Get-UsersWithWhitespaceInMail {
	<#
	.SYNOPSIS
	Get AD users that have whitespace in their mail attribute.

	.DESCRIPTION
	This function retrieves Active Directory users whose mail attribute contains whitespace characters. This can cause problems
	with some systems and applications, so it's useful to identify these users and remove the whitespace.

	.PARAMETER ExportCsv
	Use this switch to export the results to a CSV file.

	.EXAMPLE
	Get-UsersWithWhitespaceInMail

	This command retrieves all AD users with whitespace in their mail attribute and displays the results in the console.

	.EXAMPLE
	Get-UsersWithWhitespaceInMail -ExportCsv

	This command retrieves all AD users with whitespace in their mail attribute and exports the results to a CSV file named 'Accounts with Whitespace in Mail.csv'.

	#>
	[CmdletBinding()]
	param (
		[Parameter()]
		[switch]$ExportCsv
	)

	$Pattern = '\s+'
	$Users = Get-ADUser -Filter * -Properties mail | Where-Object { $_.mail -Match $Pattern }

	if ($Users.Count -gt 0) {

		if ($ExportCsv) {
			$Users | Select-Object Name, sAMAccountName, mail, DistinguishedName | Export-Csv 'Accounts with Whitespace in Mail.csv' -NoTypeInformation
		}

		$Users
	} else {
		Write-Output 'No users found with whitespace in mail attribute.'
	}
}
