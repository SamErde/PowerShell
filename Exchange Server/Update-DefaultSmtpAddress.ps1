function Update-DefaultSmtpAddress {
    <#
    .SYNOPSIS
        Update the default SMTP address for all recipients that have email address policy disabled.
    .DESCRIPTION
        When changing the SMTP domain that is being used for an organization, this script can update the primary SMTP
        address for all recipients that have email address policy disabled. This assumes that the new address has
        already been added, but not yet set as default.
    .NOTES
        Author: Sam Erde
        Version: 0.0.4
        Modified: 2024-06-24

        See https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailbox?view=exchange-ps#-windowsemailaddress
        for more information about the differences between the -WindowsEmailAddress and -PrimarySmtpAddress parameters.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        # Current SMTP domain name
        [Parameter(Mandatory)]
        [string]
        $CurrentDomain,

        # New SMTP domain name
        [Parameter(Mandatory)]
        [string]
        $NewDomain,

        # Log filename
        [Parameter()]
        [string]
        $LogFile
    )
    
    begin {
        $StartTime = Get-Date

        # Generate a log file name if one was not specified in the parameters.
        if ( -not $PSBoundParameters.ContainsKey($LogFile) ) {
            $LogFile = "Updated Default SMTP Addresses {0}.txt" -f ($StartTime.ToString("yyyy-MM-dd HH_mm_ss"))
        }

        # Start the log string builder.
        $LogStringBuilder = [System.Text.StringBuilder]::New()

        Write-Log "Updating Primary SMTP Addresses and Windows Addresses"
        Write-Log $StartTime

        # Remove the '@' symbol if it was included in the domain name parameters.
        if ($CurrentDomain -match '^@.*') {
            $CurrentDomain = $CurrentDomain -replace '@',''
        }
        if ($NewDomain -match '^@.*') {
            $NewDomain = $NewDomain -replace '@',''
        }

        # Get all of the relevant recipients that have EmailAddressPolicy disabled.
        Write-Log "`nCurrent Domain: $CurrentDomain`nNew Domain: $NewDomain`n"
        Write-Log "Getting $CurrentDomain recipients that have EmailAddressPolicy disabled."
        # Get all recipients that have a primary address ending with @$CurrentDomain and have EmailAddressPolicy disabled.
        $Recipients = Get-Mailbox -Filter 'EmailAddressPolicyEnabled -eq $false' | Where-Object {$_.PrimarySmtpAddress -like "*@$CurrentDomain"}
        $RecipientCount = $Recipients.Count
        Write-Log "Found $RecipientCount recipients.`n"
    } # end begin block

    process {
        Write-Log "Processing $RecipientCount recipients..."
        foreach ($recipient in $Recipients) {
            Write-Log "`n$($Recipients.IndexOf($recipient)+1): $($recipient.DisplayName)"
            $CurrentPrimarySmtpAddress = $($recipient.PrimarySmtpAddress.address)
            $NewPrimarySmtpAddress = $CurrentPrimarySmtpAddress -replace "@$CurrentDomain","@$NewDomain"
            Write-Log "`tCurrent Address: $CurrentPrimarySmtpAddress`n`tNew Address:`t $NewPrimarySmtpAddress"
            # Set the PrimarySmtpAddress and the WindowsEmailAddress simultaneously with one argument.
            Set-Mailbox -Identity $recipient -WindowsEmailAddress $NewPrimarySmtpAddress -WhatIf
            # Set-Mailbox -Identity $recipient -PrimarySmtpAddress $NewPrimarySmtpAddress
        }
    } # end process block

    end {
        # Write the log file
        $FinishTime = Get-Date
        Write-Log "`n`nFinished processing $RecipientCount recipients at $FinishTime.`n"
        try {
            $LogStringBuilder.ToString() | Out-File -FilePath $LogFile -Encoding utf8 -Force
            Write-Output "The log file has been written to $LogFile."
        } catch {
            Write-Warning -Message "Unable to write to the logfile `'$LogFile`'."
            $_
        }
    } # end end block
} # end function Update-DefaultSmtpAddress

function Write-Log {
    # Write a string of text to the host and a log file simultaneously.
    [CmdletBinding()]
    [OutputType([string])]
        param (
            # The message to display and write to a log
            [Parameter(Mandatory)]
            [string]
            $LogText,

            # Type of output to send
            [Parameter()]
            [ValidateSet('Both','HostOnly','LogOnly')]
            [string]
            $Output = 'Both'
        )

        switch ($Output) {
            Both {
                Write-Host "$LogText"
                [void]$LogStringBuilder.AppendLine($LogText)
            }
            HostOnly {
                Write-Host "$LogText"
            }
            LogOnly {
                [void]$LogStringBuilder.AppendLine($LogText)
            }
        }
} # end function Write-Log
