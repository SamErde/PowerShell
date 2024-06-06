# Install just the Graph PowerShell modules related to managing Entra ID:
$IdentityModules = (@'
Microsoft.Graph.DirectoryObjects
Microsoft.Graph.Users
Microsoft.Graph.Users.Actions
Microsoft.Graph.Users.Functions
Microsoft.Graph.Groups
Microsoft.Graph.Identity.DirectoryManagement
Microsoft.Graph.Identity.Governance
Microsoft.Graph.Identity.SignIns
Microsoft.Graph.Applications
'@).Split([Environment]::NewLine)

# Check if the pre-requisite modules are installed and install them if needed
foreach ($module in $IdentityModules) {
    Write-Host -ForegroundColor Yellow -BackgroundColor DarkBlue "Checking for $module"
    if (!(Get-Module -Name $module -ListAvailable)) {
        Install-Module -Name $module -Scope CurrentUser
    }
}
