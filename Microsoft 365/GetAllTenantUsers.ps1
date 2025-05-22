# PowerShell script to get all users in Microsoft 365 tenant using Microsoft Graph API
# This script requires the Microsoft.Graph PowerShell module

# Check if Microsoft.Graph module is installed and install if needed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Host "Microsoft.Graph.Users module not found. Installing..."
    Install-Module Microsoft.Graph.Users -Scope CurrentUser -Force
}

# Import required modules
Import-Module Microsoft.Graph.Users

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

# Get all users from the tenant
$users = Get-MgUser -All

# Display user information
$users | Select-Object DisplayName, UserPrincipalName, Id, JobTitle, Department | Format-Table -AutoSize

# Export to CSV file (Optional)
$csvPath = Join-Path -Path $PSScriptRoot -ChildPath "TenantUsers_$(Get-Date -Format 'yyyyMMdd').csv"
$users | Select-Object DisplayName, UserPrincipalName, Id, Mail, JobTitle, Department, AccountEnabled | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "Total users found: $($users.Count)"
Write-Host "Users exported to: $csvPath"

# Disconnect from Microsoft Graph
Disconnect-MgGraph