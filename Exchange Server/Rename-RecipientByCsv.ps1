function Rename-RecipientByCsv {
    <#
    .SYNOPSIS
        Change the name, alias, and email address of a recipient in Exchange Server.
    .DESCRIPTION
        This function allows you to use a CSV file to change the name, alias, and email address of a list of recipients
        in Exchange Server.

        The CSV file should have the following columns: alias,DisplayName,PrimaryAddress,NewAlias,NewDisplayName,NewPrimaryAddress.
    .NOTES
        Author: Sam Erde
        Version: 0.0.2
        Modified: 2024-06-21

        See https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailbox?view=exchange-ps#-windowsemailaddress
        for more information about the differences between the -WindowsEmailAddress and -PrimarySmtpAddress parameters.
    #>
    [CmdletBinding()]
    [OutputType([string],[System.IO.File])]
    param (
        # The path of the CSV file to import
        [Parameter(Mandatory)]
        [string]
        $CsvFile,

        # Log filename
        [Parameter()]
        [string]
        $LogFile
    )
    
    begin {
        $StartTime = Get-Date


        # Generate a log file name if one was not specified in the parameters.
        if ( -not $PSBoundParameters.ContainsKey($LogFile) ) {
            $LogFile = "Renaming Recipients from CSV {0}.txt" -f ($StartTime.ToString("yyyy-MM-dd HH_mm_ss"))
        }

        # Start the log string builder.
        $LogStringBuilder = [System.Text.StringBuilder]::New()

        Write-Log "Renaming Recipients in Exchange"
        Write-Log $StartTime

        # Import the CSV file (alias,DisplayName,PrimaryAddress,NewAlias,NewDisplayName,NewPrimaryAddress)
        if (Test-Path -Path $CsvFile -ErrorAction SilentlyContinue) {
            $CsvData = Import-Csv -Path $CsvFile
            $RecipientCount = $CsvData.Count
            <# This part isn't quite 100%
            if ( # Check for required properties.
                [bool]($CsvData.PSObject.Properties['alias']) -and
                [bool]($CsvData.PSObject.Properties['DisplayName']) -and
                [bool]($CsvData.PSObject.Properties['PrimarySmtpAddress']) -and
                [bool]($CsvData.PSObject.Properties['NewAlias']) -and
                [bool]($CsvData.PSObject.Properties['NewDisplayName']) -and
                [bool]($CsvData.PSObject.Properties['NewPrimarySmtpAddress'])
            ) {
                Write-Information "The CSV file contains the required columns." -InformationAction Continue
            } else {
                Write-Warning "The CSV file is missing required columns."
                break
            }
            #>
        }
        else {
            Write-Log "Unable to load the CSV file: $CsvFile."
            $_
            break
        }

    } # end begin block

    process {
        Write-Log "Processing $RecipientCount recipients..."
        foreach ($recipient in $CsvData) {
            Write-Log "`n$($recipient.DisplayName)"
            Write-Log "`tAlias: $($recipient.Alias)  >  $($recipient.NewAlias)"
            Write-Log "`tDisplayName: $($recipient.DisplayName)  >  $($recipient.NewDisplayName)"
            Write-Log "`tPrimaryAddress: $($recipient.PrimaryAddress)  >  $($recipient.NewPrimaryAddress)"
            $SetMailboxParams = @{
                Identity = $recipient.alias
                DisplayName = $recipient.NewDisplayName
                WindowsEmailAddress = $recipient.NewPrimaryAddress
                WhatIf = $false
            }
            # Set the PrimarySmtpAddress and the WindowsEmailAddress simultaneously with one argument.
            Set-Mailbox @SetMailboxParams
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
} # end function Rename-Recipient

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
