<#
.SYNOPSIS
    Creates multiple Entra ID users from a CSV file.

.DESCRIPTION
    This script reads user information from a CSV file and creates new users in Entra ID
    using the Microsoft.Entra module (specifically Microsoft.Entra.Users). The script
    validates required fields and provides detailed output for each user creation attempt.

.PARAMETER CsvPath
    The path to the CSV file containing user information.

    Supports both Microsoft bulk import format and simple format:

    Microsoft format columns:
    - "Name [displayName] Required"
    - "User name [userPrincipalName] Required"
    - "Initial password [passwordProfile] Required"
    - "Block sign in (Yes/No) [accountEnabled] Required"
    - "First name [givenName]"
    - "Last name [surname]"
    - "Job title [jobTitle]"
    - "Department [department]"
    - "Usage location [usageLocation]"
    - "Mobile phone [mobile]"
    - "Office phone [telephoneNumber]"

    Simple format columns:
    - DisplayName (Required)
    - UserPrincipalName (Required)
    - MailNickname (Required if not using Microsoft format)
    - GivenName, Surname, JobTitle, Department, OfficeLocation
    - MobilePhone, UsageLocation, AccountEnabled

.PARAMETER PasswordLength
    The length of the generated password for new users. Default is 16 characters.

.PARAMETER ForcePasswordChange
    If specified, users will be required to change their password on first sign-in.

.PARAMETER WhatIf
    Shows what would happen if the script runs without actually creating users.

.EXAMPLE
    .\New-EntraUserFromCSV.ps1 -CsvPath "C:\Users\NewUsers.csv"
    Creates users from the specified CSV file with default settings.

.EXAMPLE
    .\New-EntraUserFromCSV.ps1 -CsvPath "C:\Users\NewUsers.csv" -ForcePasswordChange
    Creates users and requires them to change their password on first sign-in.

.EXAMPLE
    .\New-EntraUserFromCSV.ps1 -CsvPath "C:\Users\NewUsers.csv" -WhatIf
    Shows what users would be created without actually creating them.

.NOTES
    Author: Sam Erde
    Version: 1.0
    Requires: Microsoft.Entra module (uses Microsoft.Entra.Users for user creation)

    Sample CSV formats:

    Simple format:
    DisplayName,UserPrincipalName,MailNickname,GivenName,Surname,JobTitle,Department,UsageLocation
    "John Doe","john.doe@contoso.com","john.doe","John","Doe","Manager","IT","US"

    Microsoft bulk import format (from Entra portal):
    "Name [displayName] Required","User name [userPrincipalName] Required","Initial password [passwordProfile] Required"
    "John Doe","john.doe@contoso.com","TempPass123!"
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [ValidateScript({
        if (-not (Test-Path -Path $_ -PathType Leaf)) {
            throw "CSV file not found: $_"
        }
        if ($_ -notmatch '\.csv$') {
            throw "File must be a CSV file: $_"
        }
        $true
    })]
    [string]$CsvPath,

    [Parameter()]
    [ValidateRange(12, 256)]
    [int]$PasswordLength = 16,

    [Parameter()]
    [switch]$ForcePasswordChange
)

#Requires -Modules Microsoft.Entra

#region Functions

function New-RandomPassword {
    <#
    .SYNOPSIS
        Generates a random password that meets Azure AD complexity requirements.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [int]$Length = 16
    )

    # Define character sets
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '0123456789'
    $special = '!@#$%^&*()-_=+[]{}|;:,.<>?'

    # Ensure at least one character from each set
    $password = @(
        $lowercase[(Get-Random -Minimum 0 -Maximum $lowercase.Length)]
        $uppercase[(Get-Random -Minimum 0 -Maximum $uppercase.Length)]
        $numbers[(Get-Random -Minimum 0 -Maximum $numbers.Length)]
        $special[(Get-Random -Minimum 0 -Maximum $special.Length)]
    )

    # Fill the rest with random characters from all sets
    $allChars = $lowercase + $uppercase + $numbers + $special
    for ($i = $password.Count; $i -lt $Length; $i++) {
        $password += $allChars[(Get-Random -Minimum 0 -Maximum $allChars.Length)]
    }

    # Shuffle the password to avoid predictable patterns
    $password = ($password | Sort-Object { Get-Random }) -join ''

    return $password
}

function Test-EntraConnection {
    <#
    .SYNOPSIS
        Tests if connected to Microsoft Graph with required permissions for the Microsoft.Entra module.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    try {
        $context = Get-EntraContext -ErrorAction SilentlyContinue
        if ($null -eq $context) {
            Write-Warning "Not connected to Microsoft Entra. Please run Connect-Entra first."
            return $false
        }

        # Check for required permission
        $requiredScopes = @('User.ReadWrite.All')
        $missingScopes = $requiredScopes | Where-Object { $_ -notin $context.Scopes }

        if ($missingScopes) {
            Write-Warning "Missing required permissions: $($missingScopes -join ', ')"
            Write-Warning "Please reconnect with: Connect-Entra -Scopes 'User.ReadWrite.All'"
            return $false
        }

        return $true
    }
    catch {
        Write-Warning "Error checking Microsoft Entra connection: $_"
        return $false
    }
}

function Get-CsvColumnMapping {
    <#
    .SYNOPSIS
        Creates a mapping between CSV columns and user properties.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory)]
        [string[]]$ColumnNames
    )

    $mapping = @{}

    # Check if this is Microsoft bulk import format
    $isMicrosoftFormat = $ColumnNames -match '\[.*\]'

    if ($isMicrosoftFormat) {
        # Microsoft bulk import format
        foreach ($column in $ColumnNames) {
            switch -Regex ($column) {
                'displayName' { $mapping['DisplayName'] = $column }
                'userPrincipalName' { $mapping['UserPrincipalName'] = $column }
                'passwordProfile' { $mapping['Password'] = $column }
                'accountEnabled' { $mapping['AccountEnabled'] = $column }
                'givenName' { $mapping['GivenName'] = $column }
                'surname' { $mapping['Surname'] = $column }
                'jobTitle' { $mapping['JobTitle'] = $column }
                'department' { $mapping['Department'] = $column }
                'usageLocation' { $mapping['UsageLocation'] = $column }
                'mobile' { $mapping['MobilePhone'] = $column }
                'telephoneNumber' { $mapping['OfficePhone'] = $column }
                'streetAddress' { $mapping['StreetAddress'] = $column }
                'city' { $mapping['City'] = $column }
                'state' { $mapping['State'] = $column }
                'country' { $mapping['Country'] = $column }
                'postalCode' { $mapping['PostalCode'] = $column }
                'physicalDeliveryOfficeName' { $mapping['OfficeLocation'] = $column }
            }
        }
    }
    else {
        # Simple format - direct mapping
        foreach ($column in $ColumnNames) {
            $mapping[$column] = $column
        }
    }

    return $mapping
}

function Get-UserPropertyValue {
    <#
    .SYNOPSIS
        Gets a property value from a user object using the column mapping.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$User,

        [Parameter(Mandatory)]
        [string]$PropertyName,

        [Parameter(Mandatory)]
        [hashtable]$Mapping
    )

    $columnName = $Mapping[$PropertyName]
    if ($columnName -and $User.PSObject.Properties[$columnName]) {
        $value = $User.$columnName
        if ($value -and $value -ne '') {
            return $value.Trim()
        }
    }
    return $null
}

#endregion Functions

#region Main Script

try {

    <# Check connection to Microsoft Entra
    if (-not (Test-EntraConnection)) {
        Write-Host "`nAttempting to connect to Microsoft Entra..." -ForegroundColor Cyan
        try {
            Connect-Entra -Scopes 'User.ReadWrite.All' -ErrorAction Stop
            Write-Host "Successfully connected to Microsoft Entra." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to connect to Microsoft Entra: $_"
            Write-Host "`nPlease ensure you have the Microsoft.Entra module installed and try again." -ForegroundColor Yellow
            Write-Host "Install with: Install-Module -Name Microsoft.Entra -Scope CurrentUser" -ForegroundColor Yellow
            exit 1
        }
    } #>

    # Import CSV file
    Write-Host "`nImporting user data from CSV..." -ForegroundColor Cyan
    Write-Verbose "CSV Path: $CsvPath"
    $allRows = Import-Csv -Path $CsvPath -ErrorAction Stop
    Write-Verbose "Imported $($allRows.Count) total rows from CSV"

    # Skip version row if present (Microsoft format)
    $users = $allRows | Where-Object {
        $_.PSObject.Properties.Value -notmatch '^version:'
    }
    Write-Verbose "Filtered to $($users.Count) user rows (version rows excluded)"

    if ($users.Count -eq 0) {
        throw "CSV file contains no data."
    }

    Write-Host "Found $($users.Count) user(s) to process." -ForegroundColor Green

    # Get column mapping
    $csvColumns = $users[0].PSObject.Properties.Name
    Write-Verbose "CSV columns detected: $($csvColumns.Count) columns"
    $columnMapping = Get-CsvColumnMapping -ColumnNames $csvColumns
    Write-Verbose "Column mapping created with $($columnMapping.Count) mapped properties"

    # Detect CSV format
    $isMicrosoftFormat = $csvColumns -match '\[.*\]'
    if ($isMicrosoftFormat) {
        Write-Host "Detected Microsoft bulk import CSV format." -ForegroundColor Cyan
        Write-Verbose "Using Microsoft Entra portal bulk import column format"
    }
    else {
        Write-Host "Detected simple CSV format." -ForegroundColor Cyan
        Write-Verbose "Using simple column name format"
    }

    # Validate required columns exist
    if (-not $columnMapping.ContainsKey('DisplayName')) {
        throw "CSV file is missing DisplayName column."
    }
    if (-not $columnMapping.ContainsKey('UserPrincipalName')) {
        throw "CSV file is missing UserPrincipalName column."
    }
    Write-Verbose "Required columns validated successfully"
    Write-Host ""

    # Track results
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $successCount = 0
    $failCount = 0

    # Process each user
    foreach ($user in $users) {
        $userPrincipalName = Get-UserPropertyValue -User $user -PropertyName 'UserPrincipalName' -Mapping $columnMapping
        $displayName = Get-UserPropertyValue -User $user -PropertyName 'DisplayName' -Mapping $columnMapping

        if (-not $userPrincipalName -or -not $displayName) {
            Write-Host "SKIPPED: Missing required fields (DisplayName or UserPrincipalName)" -ForegroundColor Yellow
            continue
        }

        Write-Host "Processing: $userPrincipalName" -ForegroundColor Cyan
        Write-Verbose "  DisplayName: $displayName"

        try {
            # Check if CSV provides password or generate one
            $providedPassword = Get-UserPropertyValue -User $user -PropertyName 'Password' -Mapping $columnMapping
            $password = if ($providedPassword) { $providedPassword } else { New-RandomPassword -Length $PasswordLength }

            if ($providedPassword) {
                Write-Verbose "  Using password from CSV"
            }
            else {
                Write-Verbose "  Generated random password (length: $PasswordLength)"
            }

            # Create PasswordProfile object (required by Microsoft.Entra module)
            $passwordProfile = New-Object Microsoft.Open.AzureAD.Model.PasswordProfile
            $passwordProfile.Password = $password
            $passwordProfile.ForceChangePasswordNextLogin = $ForcePasswordChange.IsPresent
            Write-Verbose "  PasswordProfile created (ForceChangePasswordNextLogin: $($ForcePasswordChange.IsPresent))"

            # Determine MailNickname
            $mailNickname = Get-UserPropertyValue -User $user -PropertyName 'MailNickname' -Mapping $columnMapping
            if (-not $mailNickname) {
                # Generate from UserPrincipalName
                $mailNickname = $userPrincipalName -replace '@.*$'
                Write-Verbose "  Generated MailNickname: $mailNickname"
            }
            else {
                Write-Verbose "  Using MailNickname from CSV: $mailNickname"
            }

            # Handle AccountEnabled (Microsoft format uses "Block sign in (Yes/No)")
            $accountEnabledValue = Get-UserPropertyValue -User $user -PropertyName 'AccountEnabled' -Mapping $columnMapping
            $accountEnabled = if ($accountEnabledValue) {
                # Microsoft format: "Yes" = blocked, "No" = enabled
                if ($accountEnabledValue -eq 'Yes') { $false } else { $true }
            }
            else { $true }
            Write-Verbose "  AccountEnabled: $accountEnabled"

            # Build user parameters
            $userParams = @{
                DisplayName       = $displayName
                UserPrincipalName = $userPrincipalName
                MailNickname      = $mailNickname
                PasswordProfile   = $passwordProfile
                AccountEnabled    = $accountEnabled
            }
            Write-Verbose "  Base user parameters configured"

            # Add optional properties if present
            $givenName = Get-UserPropertyValue -User $user -PropertyName 'GivenName' -Mapping $columnMapping
            if ($givenName) {
                $userParams['GivenName'] = $givenName
                Write-Verbose "  Added GivenName: $givenName"
            }

            $surname = Get-UserPropertyValue -User $user -PropertyName 'Surname' -Mapping $columnMapping
            if ($surname) {
                $userParams['Surname'] = $surname
                Write-Verbose "  Added Surname: $surname"
            }

            $jobTitle = Get-UserPropertyValue -User $user -PropertyName 'JobTitle' -Mapping $columnMapping
            if ($jobTitle) {
                $userParams['JobTitle'] = $jobTitle
                Write-Verbose "  Added JobTitle: $jobTitle"
            }

            $department = Get-UserPropertyValue -User $user -PropertyName 'Department' -Mapping $columnMapping
            if ($department) {
                $userParams['Department'] = $department
                Write-Verbose "  Added Department: $department"
            }

            $officeLocation = Get-UserPropertyValue -User $user -PropertyName 'OfficeLocation' -Mapping $columnMapping
            if ($officeLocation) {
                $userParams['OfficeLocation'] = $officeLocation
                Write-Verbose "  Added OfficeLocation: $officeLocation"
            }

            $mobilePhone = Get-UserPropertyValue -User $user -PropertyName 'MobilePhone' -Mapping $columnMapping
            if ($mobilePhone) {
                $userParams['MobilePhone'] = $mobilePhone
                Write-Verbose "  Added MobilePhone: $mobilePhone"
            }

            $usageLocation = Get-UserPropertyValue -User $user -PropertyName 'UsageLocation' -Mapping $columnMapping
            if ($usageLocation) {
                $userParams['UsageLocation'] = $usageLocation
                Write-Verbose "  Added UsageLocation: $usageLocation"
            }

            # Create the user
            if ($PSCmdlet.ShouldProcess($userPrincipalName, "Create Entra ID user")) {
                try {
                    Write-Verbose "  Calling New-EntraUser with $($userParams.Count) parameters"
                    $newUser = New-EntraUser @userParams -ErrorAction Stop

                    Write-Host "  SUCCESS: User created" -ForegroundColor Green
                    Write-Verbose "  User ObjectId: $($newUser.Id)"
                    $successCount++

                    # Store result
                    $results.Add([PSCustomObject]@{
                        UserPrincipalName = $userPrincipalName
                        DisplayName       = $displayName
                        Status            = 'Success'
                        Password          = $password
                        ObjectId          = $newUser.Id
                        Error             = $null
                    })
                    Write-Verbose "  Result stored in collection"
                }
                catch {
                    # Check for insufficient privileges error
                    if ($_.Exception.Message -match 'Insufficient privileges|Authorization_RequestDenied|403|Forbidden') {
                        Write-Host "  FAILED: Insufficient privileges to create users" -ForegroundColor Red
                        Write-Verbose "Permission error detected: $($_.Exception.Message)"
                        Write-Host "`nERROR: Your account does not have the required permissions to create users." -ForegroundColor Red
                        Write-Host "Required permission: User.ReadWrite.All" -ForegroundColor Yellow
                        Write-Host "`nPlease disconnect and reconnect with the correct scopes:" -ForegroundColor Yellow
                        Write-Host "  Disconnect-Entra" -ForegroundColor Cyan
                        Write-Host "  Connect-Entra -Scopes 'User.ReadWrite.All'" -ForegroundColor Cyan
                        Write-Host "`nScript execution stopped.`n" -ForegroundColor Red
                        exit 1
                    }

                    # Check for invalid domain error
                    if ($_.Exception.Message -match 'domain.*invalid|verified domain|InvalidValue.*userPrincipalName') {
                        $errorDetails = if ($_.ErrorDetails.Message) {
                            try {
                                $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
                                $mainMessage = $errorJson.error.message
                                $targetInfo = if ($errorJson.error.details) {
                                    $errorJson.error.details | ForEach-Object { "Target: $($_.target), Message: $($_.message)" }
                                }
                                else { $null }

                                if ($targetInfo) {
                                    "$mainMessage`n  Details: $($targetInfo -join '; ')"
                                }
                                else {
                                    $mainMessage
                                }
                            }
                            catch {
                                $_.ErrorDetails.Message
                            }
                        }
                        else {
                            $_.Exception.Message
                        }

                        Write-Host "  FAILED: Invalid domain in UserPrincipalName" -ForegroundColor Red
                        Write-Verbose "Domain validation error: $errorDetails"
                        Write-Host "  Error: $errorDetails" -ForegroundColor Yellow

                        # Extract domain from UPN
                        $domain = $userPrincipalName -replace '^[^@]+@', ''
                        Write-Host "  Domain used: $domain (not verified in your tenant)" -ForegroundColor Yellow
                        Write-Host "  Suggestion: Update the CSV to use a verified domain for your tenant" -ForegroundColor Cyan

                        # Continue to next user instead of stopping
                        $failCount++
                        $results.Add([PSCustomObject]@{
                            UserPrincipalName = $userPrincipalName
                            DisplayName       = $displayName
                            Status            = 'Failed'
                            Password          = $null
                            ObjectId          = $null
                            Error             = "Invalid domain: $domain - $errorDetails"
                        })
                        Write-Verbose "  Error result stored in collection"
                        Write-Host ""
                        continue
                    }

                    # Re-throw other errors to be caught by outer catch block
                    throw
                }
            }
            else {
                Write-Host "  SKIPPED: WhatIf mode" -ForegroundColor Yellow
                Write-Verbose "  Would have created user with parameters: $($userParams.Keys -join ', ')"
            }
        }
        catch {
            # Parse error details from API response
            $errorMessage = $_.Exception.Message
            $detailedError = $errorMessage

            if ($_.ErrorDetails.Message) {
                try {
                    $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
                    if ($errorJson.error) {
                        $detailedError = $errorJson.error.message

                        # Add detailed information if available
                        if ($errorJson.error.details) {
                            $additionalDetails = $errorJson.error.details | ForEach-Object {
                                "[$($_.target)]: $($_.message)"
                            }
                            $detailedError += "`n    " + ($additionalDetails -join "`n    ")
                        }

                        # Add inner error information if available
                        if ($errorJson.error.innerError) {
                            Write-Verbose "  Inner Error - Request ID: $($errorJson.error.innerError.'request-id')"
                            Write-Verbose "  Inner Error - Date: $($errorJson.error.innerError.date)"
                        }
                    }
                }
                catch {
                    Write-Verbose "Could not parse error details JSON: $_"
                }
            }

            Write-Host "  FAILED: $detailedError" -ForegroundColor Red
            Write-Verbose "Full error details: $($_.Exception | Format-List -Force | Out-String)"
            Write-Verbose "Error category: $($_.CategoryInfo.Category)"
            Write-Verbose "Error reason: $($_.CategoryInfo.Reason)"

            $failCount++

            # Store error result with detailed information
            $results.Add([PSCustomObject]@{
                UserPrincipalName = $userPrincipalName
                DisplayName       = $displayName
                Status            = 'Failed'
                Password          = $null
                ObjectId          = $null
                Error             = $detailedError
            })
            Write-Verbose "  Error result stored in collection"
        }

        Write-Host ""
    }

    Write-Verbose "User processing loop completed. Success: $successCount, Failed: $failCount"

    # Display summary
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "User Creation Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total Users Processed: $($users.Count)" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Red' } else { 'White' })
    Write-Host "========================================`n" -ForegroundColor Cyan

    # Export results
    if (-not $WhatIfPreference) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $resultPath = Join-Path -Path (Split-Path -Path $CsvPath -Parent) -ChildPath "UserCreation_Results_$timestamp.csv"
        Write-Verbose "Exporting results to: $resultPath"
        $results | Export-Csv -Path $resultPath -NoTypeInformation

        Write-Host "Results exported to: $resultPath" -ForegroundColor Green
        Write-Host "IMPORTANT: Store the passwords securely!" -ForegroundColor Yellow
        Write-Verbose "Results file contains $($results.Count) records"
    }
    else {
        Write-Verbose "Skipping results export due to WhatIf mode"
    }

    # Display results table
    if ($results.Count -gt 0) {
        Write-Host "`nDetailed Results:" -ForegroundColor Cyan
        Write-Verbose "Displaying results table with $($results.Count) entries"
        $results | Format-Table -AutoSize
    }
}
catch {
    Write-Error "Script execution failed: $_"
    Write-Verbose "Fatal error details: $($_.Exception | Format-List -Force | Out-String)"
    exit 1
}
finally {
    Write-Host "`nScript execution completed." -ForegroundColor Cyan
    Write-Verbose "Script finished at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

#endregion Main Script
