Function Get-EntraIdSyncAccount {
    <#
    .SYNOPSIS
        Retrieves the Entra ID Connect directory synchronization account information.

    .DESCRIPTION
        This function uses Microsoft Graph API to identify the service account
        being used by Entra ID Connect for directory synchronization.

    .PARAMETER TenantId
        The Entra ID tenant ID. If not specified, uses the default tenant.

    .EXAMPLE
        Get-EntraIdSyncAccount
        Retrieves the sync account information for the default tenant.

    .EXAMPLE
        Get-EntraIdSyncAccount -TenantId "contoso.onmicrosoft.com"
        Retrieves the sync account for a specific tenant.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [String]$TenantId
    )

    Try {
        # Connect to Microsoft Graph if not already connected
        $Context = Get-MgContext -ErrorAction SilentlyContinue

        If (-not $Context) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
            If ($TenantId) {
                Connect-MgGraph -Scopes "Directory.Read.All", "Organization.Read.All" -TenantId $TenantId -ErrorAction Stop
            } Else {
                Connect-MgGraph -Scopes "Directory.Read.All", "Organization.Read.All" -ErrorAction Stop
            }
        }

        # Check organization sync status
        Write-Host "Checking organization sync status..." -ForegroundColor Cyan
        $Organization = Get-MgOrganization -ErrorAction Stop

        If ($Organization.OnPremisesSyncEnabled -eq $True) {
            Write-Host "Directory synchronization is enabled." -ForegroundColor Green
            Write-Host "Last sync: $($Organization.OnPremisesLastSyncDateTime)" -ForegroundColor Green
            Write-Host ""
        } Else {
            Write-Warning "Directory synchronization is not enabled for this tenant."
            Return
        }

        # Search for sync accounts (typically start with "Sync_")
        Write-Host "Searching for directory sync accounts..." -ForegroundColor Cyan
        $Filter = "startsWith(displayName,'Sync_') or startsWith(userPrincipalName,'Sync_')"
        $SyncAccounts = Get-MgUser -Filter $Filter -All -ErrorAction Stop

        If ($SyncAccounts) {
            Write-Host "Found $($SyncAccounts.Count) sync account(s):" -ForegroundColor Green
            Write-Host ""

            ForEach ($Account in $SyncAccounts) {
                [PSCustomObject]@{
                    DisplayName       = $Account.DisplayName
                    UserPrincipalName = $Account.UserPrincipalName
                    ObjectId          = $Account.Id
                    AccountEnabled    = $Account.AccountEnabled
                    CreatedDateTime   = $Account.CreatedDateTime
                    UserType          = $Account.UserType
                }
            }
        } Else {
            Write-Warning "No sync accounts found with standard naming pattern."
            Write-Host "Attempting alternative search..." -ForegroundColor Cyan

            # Try finding accounts with directory sync role
            $DirectoryRole = Get-MgDirectoryRole -Filter "displayName eq 'Directory Synchronization Accounts'" -ErrorAction SilentlyContinue

            If ($DirectoryRole) {
                $RoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $DirectoryRole.Id -ErrorAction Stop

                If ($RoleMembers) {
                    Write-Host "Found accounts with Directory Synchronization role:" -ForegroundColor Green
                    Write-Host ""

                    ForEach ($Member in $RoleMembers) {
                        $User = Get-MgUser -UserId $Member.Id -ErrorAction SilentlyContinue
                        If ($User) {
                            [PSCustomObject]@{
                                DisplayName       = $User.DisplayName
                                UserPrincipalName = $User.UserPrincipalName
                                ObjectId          = $User.Id
                                AccountEnabled    = $User.AccountEnabled
                                CreatedDateTime   = $User.CreatedDateTime
                                UserType          = $User.UserType
                            }
                        }
                    }
                }
            } Else {
                Write-Warning "Could not find directory synchronization accounts."
            }
        }
    } Catch {
        Write-Error "An error occurred: $_"
    }
}
