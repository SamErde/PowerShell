# Install the required modules if they are not already installed
try {
    if (-not (Get-Module -Name 'Microsoft.Graph.Authentication' -ListAvailable)) {
        Install-Module -Name 'Microsoft.Graph.Authentication' -Scope CurrentUser -Force -AllowClobber
    }
    if (-not (Get-Module -Name 'Microsoft.Graph.Users' -ListAvailable)) {
        Install-Module -Name 'Microsoft.Graph.Users' -Scope CurrentUser -Force -AllowClobber
    }
} catch {
    Write-Warning "Failed to find or install the required modules. $_"
    return
}

# Import the required modules
Import-Module -Name 'Microsoft.Graph.Authentication'
Import-Module -Name 'Microsoft.Graph.Users'

# Connect to Microsoft Graph with a specific tenant ID and permission scopes.
$TenantId = "__________"
Connect-Graph -TenantId $TenantId -NoWelcome -Scopes "User.Read.All","User.ReadWrite.All"

# Get all users
$Users = Get-MgUser -All:$true -ConsistencyLevel eventual

# Create an array to store the gathered user details
[System.Collections.Generic.List[PSCustomObject]]$Details = @()

# Loop through each user and get specific details. Only capturing the manager and Viva Insights license (WORKPLACE_ANALYTICS) if they are assigned.
foreach ($u in $users) {
    $Details.Add( [PSCustomObject]@{
        DisplayName = $u.DisplayName
        Title = $u.JobTitle
        Department = $u.Department
        Manager = if (Get-MgUserManager -UserId $($u.id) -ErrorAction Ignore) { ( Get-MgUser -UserId $((Get-MgUserManager -UserId $($u.id)).Id) ).DisplayName } else { $null }
        DirectReportCount = (Get-MgUserDirectReport -UserId $($u.Id)).Count
        VivaInsightsLicense = if ( (Get-MgUserLicenseDetail -UserId $($u.id)).SkuPartNumber -contains 'WORKPLACE_ANALYTICS' ) { $true } else { $false}
        UserPrincipalName = $u.UserPrincipalName
        CompanyName = $u.CompanyName
    } )
}

# Show all users who are licensed for Viva Insights (WORKPLACE_ANALYTICS) but do not have a manager assigned in Entra ID
$NoManager = $Details | Where-Object {
    ( $_.VivaInsightsLicense -eq $true -and [string]::IsNullOrEmpty($_.Manager) )
}
# Show the results as a table
$NoManager | Format-Table -AutoSize

# Get disabled users that still have a Viva Insights license.
$DisabledUsers = Get-MgUser -All:$true -Filter "accountEnabled eq false" -ConsistencyLevel eventual
foreach ($u in $DisabledUsers) {
    if ( (Get-MgUserLicenseDetail -UserId $($u.id)).SkuPartNumber -contains 'WORKPLACE_ANALYTICS' ) { $true } else { $false}
}
