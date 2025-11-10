function Convert-HybridGroupToCloud {
    <#
    .SYNOPSIS
        Convert synchronized Active Directory groups from hybrid to cloud-managed.

    .DESCRIPTION
        Reads group identifiers from a text file or resolves them by display name, checks each group's
        OnPremisesSyncEnabled property, and if applicable, calls the onPremisesSyncBehavior API to set
        isCloudManaged to true. This effectively changes the source of authority (SOA) for groups from Active Directory
        to Entra ID.

    .PARAMETER FilePath
        Path to a text file that contains one group Id (GUID) per line.
        Cannot be used with the Group parameter.

    .PARAMETER Group
        One or more group display names to target.
        Accepts input from the pipeline.
        Cannot be used with the FilePath parameter.

    .EXAMPLE
        Convert-HybridGroupToCloud -FilePath "C:\temp\groups.txt"

        Converts the SOA for list of group IDs in the groups.txt file.

    .EXAMPLE
        'HR Team','Finance' | Convert-HybridGroupToCloud -Confirm

        Converts the SOA for one or more groups (referenced by display name), with confirmation prompts.

    .NOTES
        Requires Microsoft.Graph.Groups PowerShell module and appropriate permissions:

            Group.ReadWrite.All
            Group-OnPremisesSyncBehavior.ReadWrite.All

        The input file should contain one group ID (GUID) per line.

        Author: Sam Erde, Sentinel Technologies
        Modified: 2025/11/09
        Version: 1.0.0

    .OUTPUTS
        PSCustomObject with properties: Id, DisplayName, OnPremisesSyncEnabled, Updated, Status, ErrorMessage
#>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            ParameterSetName = 'FromTextFile',
            Mandatory = $true,
            HelpMessage = 'The path to a text file that contains group IDs on individual lines.'
        )]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(
            ParameterSetName = 'FromGroupName',
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = 'One or more group display names to convert from synced to cloud-managed.'
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Group
    )

    begin {
        # Import Microsoft Graph Groups module
        try {
            $ModuleName = 'Microsoft.Graph.Groups'
            if (-not (Get-Module -Name $ModuleName)) {
                Import-Module -Name $ModuleName -ErrorAction Stop
            }
            Write-Verbose 'Microsoft Graph Groups module imported.'
        } catch {
            Write-Error "Failed to import the Microsoft Graph Groups module. Install with: Install-Module Microsoft.Graph.Groups -Scope CurrentUser`n$_"
            break
        }

        # Connect to Microsoft Graph if not already connected
        $Scopes = @('Group.ReadWrite.All', 'Group-OnPremisesSyncBehavior.ReadWrite.All')
        try {
            $Context = Get-MgContext
            if (-not $Context) {
                Connect-MgGraph -Scopes $Scopes -ErrorAction Stop
                Write-Verbose 'Connected to Microsoft Graph.'
            }
        } catch {
            Write-Error "Failed to connect to Microsoft Graph. $_"
            break
        }

        # Initialize collections and counters
        $GroupGUIDs = New-Object System.Collections.Generic.List[string]
        $Results = New-Object System.Collections.Generic.List[object]
        $ProcessedCount = 0
        $UpdatedCount = 0
        $SkippedCount = 0
        $ErrorCount = 0

        # From file: read and validate GUIDs immediately
        if ($PSCmdlet.ParameterSetName -eq 'FromTextFile') {
            # Get all non-blank lines. To do: validate group IDs or provide alternative processing of group names.
            $Lines = Get-Content -Path $FilePath -ErrorAction Stop | Where-Object { $_ -and $_.Trim() -ne '' }
            if (-not $Lines -or $Lines.Count -eq 0) {
                Write-Error 'No group IDs found in the input file.'
                break
            }

            # Trim leading and trailing whitepace from each line and add the group GUID to the list.
            foreach ($Line in $Lines) {
                $Trimmed = $Line.Trim()
                try {
                    #[void][guid]$Trimmed
                    [void]$GroupGuids.Add($Trimmed)
                } catch {
                    Write-Warning "Skipping invalid GUID in input file: $Trimmed"
                }
            } # end foreach line
        } # end if FromTextFile

        # Resolve names to IDs if needed.
        if ($PSCmdlet.ParameterSetName -eq 'FromGroupName' -and $Group.Count -gt 0) {
            try {
                foreach ($GetGroup in $Group) {
                    # Escape single quotation marks in group names.
                    $EscapedGroupName = $GetGroup.Replace("'", "''")
                    # Should I use [regex]::Escape($GetGroup) instead?
                    $ResolvedGroupId = Get-MgGroup -Filter "DisplayName eq '$EscapedGroupName'" -ConsistencyLevel eventual -CountVariable _ -ErrorAction Stop |
                        Select-Object -ExpandProperty Id -ErrorAction Stop
                    # If group IDs are found online, add them to the GroupGUIDs list.
                    if ($ResolvedGroupId) {
                        foreach ($Id in @($Resolved)) { [void]$GroupGuids.Add([string]$Id) }
                    } else {
                        Write-Warning "No group found with display name: $GetGroup"
                    }
                } # end foreach GroupNameBuffer
            } catch {
                Write-Error "A problem occurred while getting groups from Entra ID. $_"
            }
        } # end if FromGroupName

        if ($GroupGUIDs.Count -eq 0) {
            Write-Error 'No valid group IDs to process.'
            return
        }

        Write-Information "Found $($GroupGUIDs.Count) group Id(s) to process." -InformationAction Continue
        $TotalGroups = $GroupGuids.Count

    } # end begin block

    process {
        foreach ($GroupId in $GroupGUIDs) {
            $ProcessedCount++
            Write-Verbose "Processing $GroupId ($ProcessedCount/$TotalGroups)"

            try {
                $GroupObject = Get-MgGroup -GroupId $GroupId -Property 'Id,DisplayName,OnPremisesSyncEnabled' -ErrorAction Stop

                Write-Verbose "Group Name: $($GroupObject.DisplayName)"
                Write-Verbose "OnPremisesSyncEnabled: $($GroupObject.OnPremisesSyncEnabled)"

                if ($GroupObject.OnPremisesSyncEnabled -eq $true) {
                    # OnPremisesSyncEnabled is true for this group ID.
                    $Action = 'Set isCloudManaged to true'
                    $Target = $GroupObject.DisplayName

                    if ($PSCmdlet.ShouldProcess($Target, $Action)) {
                        try {
                            $Body = @{ isCloudManaged = $true }
                            $Uri = "https://graph.microsoft.com/v1.0/groups/$GroupId/onPremisesSyncBehavior"
                            Invoke-MgGraphRequest -Uri $Uri -Method PATCH -Body ($Body | ConvertTo-Json) -ContentType 'application/json' -ErrorAction Stop

                            $UpdatedCount++
                            $Results.Add([PSCustomObject]@{
                                    Id                    = $GroupObject.Id
                                    DisplayName           = $GroupObject.DisplayName
                                    OnPremisesSyncEnabled = $GroupObject.OnPremisesSyncEnabled
                                    Updated               = $true
                                    Status                = 'Updated'
                                    ErrorMessage          = $null
                                }) | Out-Null
                            Write-Information "SUCCESS: Updated '$Target' to cloud-managed." -InformationAction Continue
                        } catch {
                            $ErrorCount++
                            $Results.Add([PSCustomObject]@{
                                    Id                    = $GroupObject.Id
                                    DisplayName           = $GroupObject.DisplayName
                                    OnPremisesSyncEnabled = $GroupObject.OnPremisesSyncEnabled
                                    Updated               = $false
                                    Status                = 'Error'
                                    ErrorMessage          = $_.Exception.Message
                                }) | Out-Null
                            Write-Error "Failed to update group '$Target'. $_"
                        }
                    } else {
                        $SkippedCount++
                        $Results.Add([PSCustomObject]@{
                                Id                    = $GroupObject.Id
                                DisplayName           = $GroupObject.DisplayName
                                OnPremisesSyncEnabled = $GroupObject.OnPremisesSyncEnabled
                                Updated               = $false
                                Status                = 'WhatIf/Skipped'
                                ErrorMessage          = $null
                            }) | Out-Null
                    }
                } else {
                    # OnPremisesSyncEnabled is false for this group ID.
                    $SkippedCount++
                    $Results.Add([PSCustomObject]@{
                            Id                    = $GroupObject.Id
                            DisplayName           = $GroupObject.DisplayName
                            OnPremisesSyncEnabled = $GroupObject.OnPremisesSyncEnabled
                            Updated               = $false
                            Status                = 'NotSyncEnabled'
                            ErrorMessage          = $null
                        }) | Out-Null
                    Write-Verbose 'SKIPPED: Group is not on-premises synchronized.'
                }
            } catch {
                $ErrorCount++
                $Results.Add([PSCustomObject]@{
                        Id                    = $GroupId
                        DisplayName           = $null
                        OnPremisesSyncEnabled = $null
                        Updated               = $false
                        Status                = 'LookupError'
                        ErrorMessage          = $_.Exception.Message
                    }) | Out-Null
                Write-Error "Failed to retrieve group information for $GroupId. $_"
            }
        } # end foreach GroupGUIDs

        Write-Information "`n-----------------------------------" -InformationAction Continue
        Write-Information 'SUMMARY' -InformationAction Continue
        Write-Information '-----------------------------------' -InformationAction Continue
        Write-Information "Total groups processed: $TotalGroups" -InformationAction Continue
        Write-Information "Successfully updated:  $UpdatedCount" -InformationAction Continue
        Write-Information "Skipped (not sync-enabled or WhatIf): $SkippedCount" -InformationAction Continue
        Write-Information "Errors encountered:    $ErrorCount" -InformationAction Continue

        # Emit results to the pipeline
        $Results
    } # end process block
} # end Convert-HybridGroupToCloud function
