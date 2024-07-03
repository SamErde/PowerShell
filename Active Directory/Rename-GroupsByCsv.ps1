function Rename-GroupsByCsv {
    <#
        .SYNOPSIS
        Renames a list of groups based on a CSV file.

        .DESCRIPTION
        This function renames a list of Active Directory groups based on
        a CSV file that contains values in two columns: OldName and NewName.

        .PARAMETER CsvFile
        The path to the CSV file that contains the list of groups to rename.

        .PARAMETER LogFile
        Path and filename to save logs in.

        .EXAMPLE
        Rename-GroupsByCSV -CsvFile 'C:\Path\To\GroupList.csv'

        Renames the groups listed in the CSV file.

        .NOTES
        Author: Sam Erde
        Version: 0.0.2
        Modified: 2024-06-28
    #>

    [CmdletBinding()]
    param (
        # The CSV file containing a list of groups. Required columns: GroupName,NewGroupName. Optional column: GPO.
        [Parameter(Mandatory, Position = 0)]
        [string]
        $CsvFile,

        # Log path and filename. A default name will be generated if none is provided.
        [Parameter()]
        [string]
        $LogFile
    )

    begin {
        $StartTime = Get-Date

        # Generate a log file name if one was not specified in the parameters.
        if ( -not $PSBoundParameters.ContainsKey($LogFile) ) {
            $LogFile = "Renaming Groups from CSV {0}.txt" -f ($StartTime.ToString("yyyy-MM-dd HH_mm_ss"))
        }

        # Start the log string builder.
        $LogStringBuilder = [System.Text.StringBuilder]::New()

        Write-Log "Renaming Security Groups from $CsvFile."
        Write-Log "$StartTime `n"

        try {
            $GroupsCsv = Import-Csv -Path $CsvFile -Delimeter ';'
        } catch {
            Write-Log -LogText "Failed to import the CSV file `'$GroupsCsv`'.`n$_"
            break
        }

        Import-Module ActiveDirectory
    } # end begin block
    
    process {
        foreach ($group in $GroupsCsv) {
            try {
                $OldName = $group.GroupName
                $NewName = $group.NewGroupName
                Get-ADGroup $OldName | Set-ADGroup -SamAccountName $NewName -DisplayName $NewName -WhatIf
                Write-Log -LogText "$(Get-Date) [Renamed] `'$OldName`' renamed to `'$NewName`'." -Output Both
            } catch {
                Write-Log -LogText "$(Get-Date) [Failed] Failed to rename `'$OldName`'.`n$_" -Output Both
            }
        } # end foreach group
    } # end process block
    
    end {
        # Write the log file
        $FinishTime = Get-Date
        Write-Log "`n`nFinished renaming $GroupCount groups at $FinishTime.`n"
        try {
            $LogStringBuilder.ToString() | Out-File -FilePath $LogFile -Encoding utf8 -Force
            Write-Output "The log file has been written to $LogFile."
        } catch {
            Write-Warning -Message "Unable to write to the logfile `'$LogFile`'."
            $_
        }
    } # end end block
} # end function Rename-GroupsByCsv

function Write-Log {
    # Write a string of text to the host and a log file simultaneously.
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Support using Write-Host and colors for interactive scripts.')]
    [OutputType([string])]
        param (
            # The message to display and write to a log
            [Parameter(Mandatory, Position = 0)]
            [string]
            $LogText,

            # Type of output to send
            [Parameter(Position = 1)]
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
    } # end switch Output
} # end function Write-Log
