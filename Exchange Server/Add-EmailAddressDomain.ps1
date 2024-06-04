function Add-EmailAddressDomain {
    <#
    .SYNOPSIS
        Copy all existing email addresses on Exchange mailboxes to include the same address with a new SMTP domain.

    .DESCRIPTION
        This script ensures that adding a new recipient domain in Exchange Server will preserve all existing email addresses for each
        mailbox while also duplicating their custom email addresses (created without email address policy templates) at the new domain.

    .PARAMETER NewDomain
        The new domain name that will be added for all existing email addresses.

    .EXAMPLE
        For a recipient with the following email addresses: user@domain.com, userFirst.userLast@domain.com, customUser@domain.com

            Add-EmailAddressDomain -NewDomain 'example.com'
        
        The script will add the following email addresses to the recipient: user@example.com, userFirst.userLast@example.com, customUser@example.com
    
    .NOTES
        Version: 1.0
        Modified: 2024-31-05
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewDomain
    )

    # Get all mailboxes in the Exchange organization and then loop through each of them.
    Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Getting mailboxes..." -InformationAction Continue
    $Recipients = Get-Mailbox -ResultSize 10 #Unlimited

    Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Processing mailboxes..." -InformationAction Continue
    foreach ($recipient in $Recipients) {

        # Get all current email addresses for the recipient. Ignore the invalid "@mail.comhs.org" domain addresses.
        Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]`t Analyzing addresses for '$($recipient.DisplayName).'" -InformationAction Continue
        $CurrentEmailAddresses = $recipient.EmailAddresses | Where-Object { $_.PrefixString -eq 'smtp' }

        foreach ($address in $CurrentEmailAddresses) {
            # Copy each current address using the new domain name.
            [string]$NewEmailAddress = $address.SmtpAddress -replace '@.*$', "@$NewDomain"

            try {
                [mailaddress]::new("$NewEmailAddress") | Out-Null
                [bool]$ValidEmailAddress = $true
            } catch {
                Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]`t`t Invalid address: '$NewEmailAddress'" -InformationAction Continue
                # Exit the loop (continue) if the address is invalid.
                [bool]$ValidEmailAddress = $false
                continue
            }

            # Skip (continue) if the new address is already found in the $CurrentEmailAddresses array so it doesn't try to add it again.
            if ($CurrentEmailAddresses -notcontains $NewEmailAddress -and $ValidEmailAddress -eq $true) {
                # Add the new email address to the recipient.
                Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]`t`t Add address: '$NewEmailAddress'" -InformationAction Continue
                Set-Mailbox -Identity $recipient.Identity -EmailAddresses @{Add="$NewEmailAddress"} -WhatIf
            }
            Write-Output "`n"
        } # End foreach $address
    } # End foreach $recipient
} # End function Add-EmailAddressDomain
