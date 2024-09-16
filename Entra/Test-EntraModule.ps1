<#
    .SYNOPSIS
    Quickly manage dependencies for testing and resetting the Microsoft.Graph.Entra PowerShell module.
#>

# Add error handling, checks for present/not present, etc.

New-Variable -Name 'EntraModuleDependencies' -Option Constant -Scope Global -Value @(
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Users.Actions',
    'Microsoft.Graph.Users.Functions',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Identity.Governance',
    'Microsoft.Graph.Identity.SignIns',
    'Microsoft.Graph.Applications',
    'Microsoft.Graph.Reports'
)

function Remove-EntraModuleDependencies {
    [CmdletBinding()]
    param ()
    foreach ($item in $EntraModuleDependencies) {
        if (Get-Module -Name $item) {
            Remove-Module -Name $item -Force -Confirm:$false
        }
    }
}

function Install-EntraModuleDependencies {
    [CmdletBinding()]
    param ()
    foreach ($item in $EntraModuleDependencies) {
        Install-Module -Name $item -RequiredVersion 2.15.0 -Scope CurrentUser -Force
    }
}

function Uninstall-EntraModuleDependencies {
    [CmdletBinding()]
    param ()
    foreach ($item in $EntraModuleDependencies) {
        Uninstall-Module -Name $item -AllVersions -Force -Confirm:$false
    }
}

function Install-EntraModule {
    [CmdletBinding()]
    param (
        $Version = '0.15.0-preview'
    )
    Install-Module -Name 'Microsoft.Graph.Entra' -RequiredVersion $Version -AllowPrerelease -Scope CurrentUser -Force
}

function Reset-EntraModuleComponents {
    [CmdletBinding()]
    param ()
    Write-Verbose -Message 'Removing the Microsoft.Graph.Entra module.' -Verbose
    Remove-Module -Name 'Microsoft.Graph.Entra' -Force -Confirm:$false
    Write-Verbose -Message 'Removing the Microsoft.Graph.Entra module''s dependency modules.' -Verbose
    Remove-EntraModuleDependencies
    Write-Verbose -Message 'Uninstalling the Microsoft.Graph.Entra module.' -Verbose
    Uninstall-Module -Name 'Microsoft.Graph.Entra' -AllVersions -Force -Confirm:$false
    Write-Verbose -Message 'Uninstalling the Microsoft.Graph.Entra module''s dependency modules.' -Verbose
    Uninstall-EntraModuleDependencies
    Write-Output 'The Microsoft.Graph.Entra module and its dependencies have been uninstalled. For best results with testing, close all instances of PowerShell before reinstalling for fresh tests.'
}

function Get-InstalledEntraModuleComponents {
    foreach ($item in $EntraModuleDependencies) {
        Get-InstalledModule -Name $item -AllVersions -AllowPrerelease
    }
}

# Add functions to test performance of importing, running first command, and getting commands.
