<#
    .SYNOPSIS
        Get all Exchange mailboxes that have an alias that ends with a digit or a primary email address that has a digit
        immediately preceding the @ symbol.
    .DESCRIPTION
        Get all Exchange mailboxes that have an alias that ends with a digit or a primary email address that has a digit
        immediately preceding the @ symbol.
    .NOTES
        Author: Sam Erde
        Modified: 2024-06-17
        Version: 0.0.2
#>

$NumberAts = Get-Mailbox -ResultSize Unlimited -SortBy alias | Where-Object {
    $_.alias -match '\d$' -or $_.PrimarySmtpAddress -match '^.*\d@.*$'
}
$NumberAts |
    Select-Object DisplayName, alias, EmailAddressPolicyEnabled, WindowsEmailAddress, PrimarySmtpAddress,
    @{Name = 'SmtpAddresses'; Expression = { $_.emailaddresses.smtpAddress -join ', ' } } |
        ConvertTo-Csv -NoTypeInformation -Delimiter ';' |
            Set-Clipboard
