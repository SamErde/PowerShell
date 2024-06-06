Install-Module ExchangeOnlineManagement
Import-Module ExchangeOnlineManagement
# Update the line below with the UPN of an Exchange Online administrator
Connect-ExchangeOnline -UserPrincipalName 'EXOAdministrator@domain.com'

# Enable a mailtip that is displayed when sending an email that includes external recipients:
Set-OrganizationConfig -MailTipsExternalRecipientsTipsEnabled $true
Get-OrganizationConfig | Format-List MailTipsExternalRecipientsTipsEnabled

# Enable a mailtip in Outlook and Outlook mobile that tags mesages from external senders:
Set-ExternalInOutlook -Enabled $true
