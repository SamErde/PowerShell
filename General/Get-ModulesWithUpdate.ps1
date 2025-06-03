function Get-ModulesWithUpdate {
    <#
    .SYNOPSIS
    Get a list of installed PowerShell modules that have updates available in the PowerShell Gallery.

    .DESCRIPTION
    This function retrieves a list of installed PowerShell modules and checks for updates available in the source repository.

    .PARAMETER Name
    The module name or list of module names to check for updates. Wildcards are allowed, and all modules are checked by default.

    .EXAMPLE
    Get-ModulesWithUpdate
    This command retrieves all installed PowerShell modules and checks for updates available in the PowerShell Gallery.

    .NOTES
    To Do: Add support for checking other repositories.

    #>
    [CmdletBinding()]
    [OutputType('PSPreworkout.ModuleInfo')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Making it pretty.')]
    param(
        # List of modules to check for updates. This parameter is accepts wildcards and checks all modules by default.
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = 'Enter a module name or names. Wildcards are allowed.'
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.Collections.Generic.List[string]] $Name = @('*')
    )

    begin {
        # Initialize a list to hold modules with updates.
        [System.Collections.Generic.List[System.Object]] $ModulesWithUpdates = @()
    } # end begin block

    process {
        # Get installed modules.
        Write-Host -ForegroundColor Cyan "Getting installed modules ($($Name -join ','))..."
        try {
            [System.Collections.Generic.List[System.Object]] $Modules = Get-InstalledModule -Name $Name
        } catch {
            throw $_
        }

        # End the script if no modules were found.
        if (-not $Modules -or $Modules.Count -eq 0) {
            Write-Warning 'No matching modules were found.'
            return
        } else {
            Write-Host "Found $($Modules.Count) installed modules.`n"
        }

        Write-Host 'Checking the repository for newer versions of the modules...' -ForegroundColor Cyan
        foreach ($Module in $Modules) {

            Write-Verbose "$($Module.Name) $($Module.Version)"

            # Use $true for the AllowPrerelease argument if the module version string contains 'beta', 'prerelease', 'preview', or 'rc'.
            $PreRelease = ( $Module.Version -match 'beta|prerelease|preview|rc' )

            try {
                # Get the latest online version. Only allow pre-release versions if a pre-release version is already installed.
                $OnlineModule = Find-Module -Name $Module.Name -AllowPrerelease:$PreRelease
                # The Get-PSResource cmdlet provides Repository name and can be optimized to check other repositories if needed.
                # If a newer version is available, create a custom object with PSPreworkout.ModuleInfo type.
                # Treat the installed version as an array in case multiple versions are installed.
                if ( ($OnlineModule.Version -as [version]) -gt @(($Module.Version))[0] ) {
                    Write-Verbose "$($Module.Name) $($Module.Version) --> $($OnlineModule.Version) 🆕"

                    # Create a custom object with PSPreworkout.ModuleInfo type
                    $ModuleInfo = [PSCustomObject]@{
                        PSTypeName      = 'PSPreworkout.ModuleInfo'
                        Name            = $Module.Name
                        Version         = $Module.Version
                        Repository      = $Module.Repository
                        Description     = $Module.Description
                        Author          = $Module.Author
                        CompanyName     = $Module.CompanyName
                        Copyright       = $Module.Copyright
                        PublishedDate   = $Module.PublishedDate
                        InstalledDate   = $Module.InstalledDate
                        UpdateAvailable = $true
                        OnlineVersion   = $OnlineModule.Version
                        ReleaseNotes    = $OnlineModule.ReleaseNotes
                    }

                    # Add the module to the list of modules with updates.
                    $ModulesWithUpdates.Add($ModuleInfo)
                }
            } catch {
                # Show a warning if the module is not found in the online repository.
                Write-Warning "Module $($Module.Name) was not found in the online repository. $_"
            }
        }

        if (-not $ModulesWithUpdates -or $ModulesWithUpdates.Count -eq 0) {
            Write-Information 'No module updates found in the online repository.'
            return
        } else {
            # Return the list of modules with updates to the host or the pipeline.
            Write-Host "Found $($ModulesWithUpdates.Count) modules with updates available." -ForegroundColor Yellow
            $ModulesWithUpdates
        }
    } # end process block
}

