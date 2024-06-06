function Add-EmailAddressDomain {
    <#
    .SYNOPSIS
        Copy all existing email addresses on Exchange mailboxes to include the same address with a new SMTP domain.

    .DESCRIPTION
        This script ensures that adding a new recipient domain in Exchange Server will preserve all existing email addresses for each
        mailbox while also duplicating their custom email addresses (created without email address policy templates) at the new domain.

    .PARAMETER NewDomain
        The new domain name that will be added for all existing email addresses.
    
    .PARAMETER CSVExportOnly
        A switch to export a CSV file that shows the current and pending email addresses instead of actually making any changes.
    
    .PARAMETER CSVExportPath
        Path to save the exported CSV report in.

    .EXAMPLE
        For a recipient with the following email addresses: user@domain.com, userFirst.userLast@domain.com, customUser@domain.com

            Add-EmailAddressDomain -NewDomain 'example.com'
        
        The script will add the following email addresses to the recipient: user@example.com, userFirst.userLast@example.com, customUser@example.com
    
    .NOTES
        Version: 1.0
        Modified: 2024-06-05

        To Do:
                Add an option to create a CSV that contains current and future addresses
                Add an option to batch changes with delays to minimize AD replication congestion
                Use SupportShouldProcess
    #>
    [CmdletBinding()]
    param (
        # Name of the domain that addresses are being created for.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewDomain,
        
        # Switch to export a CSV of potential changes instead of making changes.
        [Parameter()]
        [switch]
        $CSVExportOnly,

        # Path to save the exported CSV file to.
        [Parameter()]
        [string]
        $CSVExportPath = "Address Creation Preview for $NewDomain at $(Get-Date -Format 'yyyy-MM-dd HH.mm.ss').csv"
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

            # Only add the new address if it isn't already present.
            if ($CurrentEmailAddresses -notcontains $NewEmailAddress -and $ValidEmailAddress -eq $true) {
                # Add the new email address to the recipient.
                Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]`t`t Add address: '$NewEmailAddress'" -InformationAction Continue
                Set-Mailbox -Identity $recipient.Identity -EmailAddresses @{Add="$NewEmailAddress"} -WhatIf
            }
            Write-Output "`n"
        } # End foreach $address
    } # End foreach $recipient
} # End function Add-EmailAddressDomain
