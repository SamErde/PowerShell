function Get-GpoGroupsToRename {
    <#
        .SYNOPSIS
        Rename the security groups used for filtering GPOs.

        .DESCRIPTION
        Check the security filtering groups that are applied to group policy objects and rename them to align with the
        GPO name. This only performs the rename for groups that begin with the string "GPO".

        .PARAMETER GPO
        Name of the GPO to check for security filtering groups.

        .PARAMETER IgnoreWords
        Ignore security groups that have these words anywhere in their name. Not case-sensitive.

        .PARAMETER RequiredPrefix
        Only rename security groups that already begin with a specific prefix (eg: "GPO."). Not case-sensitive.

        .PARAMETER LogFile
        Path and filename to save logs in.

        .EXAMPLE
        Rename-GPOSecurityGroups -RequiredPrefix "GPO." -IgnoreWords "Phase"

        Run the script; only target security groups that already begin with the string "GPO." and
        ignore any security groups that contain the word "Phase".

        .EXAMPLE
        Rename-GPOSecurityGroups -IgnoreWords @("Phase","AlsoIgnoreThis","And Ignore This")

        Run the script and ignore any security groups that contain any string from the provided array.

        .NOTES
        Author: Sam Erde
        Version: 0.1.1
        Modified: 2024-07-03
    #>

    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param (
        # Name of the GPO to find and rename groups for.
        [Parameter(Position = 0)]
        $GPO,

        # Only rename security groups that already begin with a specific prefix.
        [Parameter()]
        [string]
        $RequiredPrefix = 'GPO',

        # Skip GPOs that have these words anywhere in their name:
        [Parameter()]
        [System.Collections.Generic.List[string]]
        $IgnoreWords = @(),

        # Switch to run in "report-only" mode.
        [Parameter()]
        [switch]
        $ReportOnly,

        # Log path and filename. A default name will be generated if none is provided.
        [Parameter()]
        [string]
        $LogFile
    )

    begin {
        $StartTime = Get-Date

        # Generate a log file name if one was not specified in the parameters.
        if ( -not $PSBoundParameters.ContainsKey($LogFile) ) {
            $LogFile = "GPO Security Filtering Groups to Rename {0}.txt" -f ($StartTime.ToString("yyyy-MM-dd HH_mm_ss"))
        }

        # Set a name for the exported CSV file is one is not specified.
        if (-not $PSBoundParameters.ContainsKey($CsvFile) ) {
            $GroupsToRenameCsvFile = ".\Groups to Rename {0}.csv" -f ($StartTime.ToString("yyyy-MM-dd HH_mm_ss"))
        }

        [string]$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name

        # Start the log string builder.
        $LogStringBuilder = [System.Text.StringBuilder]::New()

        Write-This "Getting GPO Security Filtering Groups to Rename"
        Write-This "$StartTime `n"

        # Initialize the list of strings include for ignoring group names:
        [System.Collections.Generic.List[string]]$DefaultIgnoreWords = @(
            'Authenticated Users','Domain Computers','Domain Controllers'
        )
        Write-This -LogText "Ignoring by default: $($DefaultIgnoreWords -join ', ')." -Output Both
        if ($IgnoreWords) {
            Write-This -LogText "Ignoring group names that include: $($IgnoreWords -join ', ')." -Output Both
        }
        $IgnoreWords.AddRange($DefaultIgnoreWords)

        # Get the GPO (or all GPOs) so we can check their security filtering groups:
        if ($GPO) {
            Write-Verbose "Checking GPO named: `'$GPO`' in $Domain"
            $GPOs = Get-Gpo $GPO -Domain $Domain
        } else {
            Write-Verbose "Checking all GPOs in $Domain."
            $GPOs = Get-GPO -All -Domain $Domain
        }
        $GpoCount = $Gpos.Count

        Write-This -LogText "`nInspecting $GpoCount GPOs in $Domain.`n" -Output Both

    } # end begin block

    process {

        [System.Collections.ArrayList]$GroupsToRename = @()

        # Loop through all GPOs to inspect ACEs with the GpoApply permission.
        foreach ($gpo in $GPOs) {
            $GpoName = $gpo.DisplayName

            [array]$GpoApply = $gpo | Get-GPPermission -All -TargetType Group -Domain $Domain | Where-Object {
                    $_.Permission -eq 'GpoApply' -and
                    $_.Trustee.SidType -eq 'Group'
                }

            if (-not $GpoApply) {
                # Security filtering is not used.
                Write-This -LogText "$(Get-Date) [Skipped] `'$GpoName`' does not use security group filtering." -Output LogOnly
                Continue
            }

            foreach ($ace in $GpoApply) {
                $GroupName = $ace.Trustee.Name

                if ( $IgnoreWords | Where-Object { $GroupName -match $_ } ) {
                    # Security filtering groups include an ignored word in the name.
                    Write-This -LogText "$(Get-Date) [Ignored] `'$GpoName`' security filtering group `'$GroupName`' includes an ignored word in the name." -Output Both
                    Continue
                }
                if ($GroupName -eq "GPO.$GpoName") {
                    # The group name matches the GPO name.
                    Write-This -LogText "$(Get-Date) [Matched] `'$GpoName`' security filtering group `'$GroupName`' matches." -Output LogOnly
                    Continue
                }

                $NewGroupName = "GPO.$GpoName"
                $GroupsToRename.Add([PSCustomObject]@{
                    GPO = $GpoName
                    GroupName = $GroupName
                    NewGroupName = $NewGroupName
                }) | Out-Null

                Write-This -LogText "`n$(Get-Date) [Mismatch] $GpoName`n`t`tGroup: $GroupName`n`t`tNew Group: $NewGroupName`n" -Output Both
            } #end foreach ace
        } # end foreach gpo
    } # end process block

    end {

        if ($GroupsToRename.Count -gt 0) {
            # Create the CSV file of groups to rename.
            try {
                $GroupsToRename | ConvertTo-Csv -NoTypeInformation -Delimiter ';' | Out-File -FilePath $GroupsToRenameCsvFile
                Write-This -LogText "A table of the potential changes has been written to `'$GroupsToRenameCsvFile`'." -Output Both
            } catch {
                Write-This -LogText "Failed to create `'$GroupsToRenameCsvFile`'.`n$_"
            }
        }

        # Write the log file
        $FinishTime = Get-Date
        Write-This "`n`nFinished reviewing $GpoCount at $FinishTime." -Output Both
        Write-This "There are $($GroupsToRename.Count) groups to review and rename." -Output Both
        try {
            $LogStringBuilder.ToString() | Out-File -FilePath $LogFile -Encoding utf8 -Force
            Write-Output "`nThe log file has been written to `'$LogFile`'."
        } catch {
            Write-Warning -Message "Unable to write to the logfile `'$LogFile`'."
            $_
        }
    } # end end block
} # end function

function Write-This {
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
} # end function Write-This
