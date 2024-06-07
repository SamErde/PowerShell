function Add-EmailAddressDomain {
    <#
    .SYNOPSIS
        Copy all existing email addresses on Exchange mailboxes to include the same address with a new SMTP domain.

    .DESCRIPTION
        This script ensures that adding a new recipient domain in Exchange Server will preserve all existing email addresses for each
        mailbox while also duplicating their custom email addresses (created without email address policy templates) at the new domain.

    .PARAMETER NewDomain
        The new domain name that will be added for all existing email addresses.
    
    .PARAMETER ReportOnly
        Create a CSV report showing current and new addresses but do not make any changes.
    
    .PARAMETER ReportFilePath
        Path to save the exported CSV report in.
    
    .PARAMETER Passthru
        Return the CSVData in the script output.
    
    .PARAMETER BatchSize
        Set the batch size for the number of recipients to update before waiting to start the next batch of changes.
        This can be used to reduce change congestion in AD replication or to minimize the number of changes that get
        synced to Entra ID (or other platforms).

    .PARAMETER Delay
        Set the number of minutes to wait between batches of changes.

    .EXAMPLE
        For a recipient with the following email addresses: user@domain.com, userFirst.userLast@domain.com, customUser@domain.com

            Add-EmailAddressDomain -NewDomain 'example.com'
        
        The script will add the following email addresses to the recipient: user@example.com, userFirst.userLast@example.com, customUser@example.com
    
    .EXAMPLE
        For a recipient with the following email addresses: user@domain.com, userFirst.userLast@domain.com, customUser@domain.com

            Add-EmailAddressDomain -NewDomain 'example.com' -BatchSize 250 -Delay 15
        
        The script will add the following email addresses to the recipient: user@example.com, userFirst.userLast@example.com, customUser@example.com
        It will update 250 recipients at a time, then wait 15 minutes before updating the next batch of 250 recipients.
    
    .EXAMPLE
        Add-EmailAddressDomain -NewDomain 'example.com' -ReportOnly -ReportFilePath '.\New Email Address Report.csv'

        Will create a CSV file that shows current email addresses next to the email addresses that would be created if
        this command is run without the -ReportOnly parameter.

    .EXAMPLE
        An example of returning the CSV data to an object outside of the function that you can continue to work with:

        $ReportData = Add-EmailAddressDomain -NewDomain 'powershealth.org' -ReportOnly -Passthru
        $ReportData | ConvertTo-Csv -NoTypeInformation -Delimiter ';' | Set-Clipboard
    
    .NOTES
        Version: 0.4.1
        Modified: 2024-06-07

        To Do:
                TESTING: Add an option to create a CSV that contains current and future addresses
                TESTING: Add an option to batch changes with delays to minimize AD replication congestion
                NOT STARTED: Use SupportShouldProcess
    #>
    [CmdletBinding()]
    param (
        # Name of the domain that addresses are being created for.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewDomain,
        
        # Switch to export a CSV of potential changes instead of making changes.
        [Parameter(ParameterSetName = 'ReportOnly')]
        [switch]
        $ReportOnly,

        # Path to save the exported CSV file to.
        [Parameter(ParameterSetName = 'ReportOnly')]
        [string]
        $ReportFilePath = "Address Creation Preview for $NewDomain at $(Get-Date -Format 'yyyy-MM-dd HH.mm.ss').csv",

        # Optionally return the CSV report data as an output object
        [Parameter(ParameterSetName = 'ReportOnly')]
        [switch]
        $Passthru,

        # Break the changes into smaller batches of recipients vs all of the things
        [Parameter(Mandatory, ParameterSetName = 'Batches')]
        [int]
        $BatchSize,

        # Specify the delay to wait between batches
        [Parameter(ParameterSetName = 'Batches')]
        [int]
        $Delay = 15
    )

    begin {
        if ($ReportOnly) {
            $CSVData = New-Object System.Collections.ArrayList
        }

        # Get all mailboxes in the Exchange organization and then loop through each of them.
        Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Getting mailboxes..." -InformationAction Continue
        $Recipients = Get-Mailbox -ResultSize Unlimited
        $RecipientCount = $Recipients.Count

        if ($Delay) {
            $DelaySeconds = (New-TimeSpan -Minutes $Delay).TotalSeconds
        }

        if ( -not $PSBoundParameters.ContainsKey('BatchSize') ) {
            $BatchSize = $RecipientCount
        }
    }

    process {
        Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Processing $RecipientCount recipients..." -InformationAction Continue

        for ($i = 0; $i -lt $RecipientCount; $i += $BatchSize) {
            if ($BatchSize) {
                Write-Information -MessageData "$i - $($i + $BatchSize)" -InformationAction Continue
            }

            foreach ($recipient in $Recipients) {

                # Get all current email addresses for the recipient. Ignore the invalid "@mail.comhs.org" domain addresses.
                Write-Information "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]`t Analyzing addresses for '$($recipient.DisplayName).'" -InformationAction Continue
                $CurrentEmailAddresses = $recipient.EmailAddresses | Where-Object { $_.PrefixString -eq 'smtp' }

                # Make the change or just preview it in a CSV?
                if ($ReportOnly) {
                    $CSVData.Add(
                        [PSCustomObject]@{
                            Name = $($recipient.DisplayName)
                            Alias = $($recipient.alias)
                            CurrentEmailAddresses = ( [string]$($CurrentEmailAddresses.addressstring) -replace ' ', ', ' )
                            NewEmailAddresses = ( [string]$($CurrentEmailAddresses.addressstring -replace '@.*$', "@$NewDomain") -replace ' ', ', ' )
                        }
                    ) | Out-Null
                    # Continue to the next recipient in report-only  mode instead of adding addresses.
                    continue
                }

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

                    # Only add the new address if it isn't already present and if not using ReportOnly.
                    if ($CurrentEmailAddresses -notcontains $NewEmailAddress -and $ValidEmailAddress -eq $true) {
                        # Add the new email address to the recipient.
                        Write-Information "`t`t`t Add address: '$NewEmailAddress'" -InformationAction Continue
                        Set-Mailbox -Identity $recipient.Identity -EmailAddresses @{Add="$NewEmailAddress"} -WhatIf
                    }
                } # End foreach $address
                Write-Output "`n"
            } # End foreach $recipient

            # Pause between batches if a delay is specified
            if ( ($i + $BatchSize -lt $RecipientCount) -and $Delay) {
                Write-Information -MessageData "Waiting for $DelaySeconds seconds..." -InformationAction Continue
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }

    end {
        # Create the CSV file if -ReportOnly created CSV data
        if ($CSVData) {
            Write-Information -MessageData "The report will be saved to '$ReportFilePath'."
            try {
                $CSVData | ConvertTo-Csv -NoTypeInformation -Delimiter ';' | Out-File -FilePath $ReportFilePath
                # OFI: Check if the file already exists and prompt the user to overwrite or save a copy.
            } catch {
                $_
            }
        }

        # Return the $CSVData object if -Passthru was specified
        if ($Passthru) {
            $CSVData
        }
    }
} # End function Add-EmailAddressDomain
