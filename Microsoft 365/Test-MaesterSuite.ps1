function Test-MaesterSuite {
<#
    .SYNOPSIS
    Update the Maester module and tests to the latest version and then import the module.

    .DESCRIPTION
    Update the Maester module and tests to the latest version and then import the module.

    .PARAMETER UpdateModule
    Update the Maester module to the latest prerelease version from the PowerShell Gallery.

    .PARAMETER UpdateTests
    Update the Maester tests to the latest version from the module's install location.

    .PARAMETER TestsPath
    Path to install or update the Maester tests in when -UpdateTests is used. Defaults to "$HOME\maester-tests".

    .PARAMETER ModuleSource
    Specifies the source for the Maester module. Valid choices are the 'Installed' version (default) and 'LocalDevelopment'.
    'Installed' imports the installed Maester module. 'LocalDevelopment' imports the local development version.

    .PARAMETER DevPath
    Path to the local development version of Maester and its tests. Defaults to "$HOME\Code\Personal\Maester".

    .PARAMETER DevBranch
    Branch to use when importing the local development version of Maester instead of the installed version. Defaults to "main".

    .PARAMETER DevTests
    Import the local development version of Maester tests instead of the installed tests.

    .PARAMETER OutputPath
    Path to save the test output files to. Defaults "$HOME\maester-results\".

    .PARAMETER NoInvoke
    Do not execute Maester tests.

    .PARAMETER IncludeLongRunning
    Include tests that are marked as long-running.

    .PARAMETER IncludePreview
    Include tests that are marked as preview.

    .EXAMPLE
    Test-MaesterSuite -UpdateModule -UpdateTests

    .EXAMPLE
    Test-MaesterSuite -ModuleSource LocalDevelopment -UpdateTests
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Update the Maester module to the latest prerelease version from the PowerShell Gallery.
        [Parameter()]
        [switch]$UpdateModule,

        # Path to install or update the Maester tests to when not using -DevTests.
        [Parameter()]
        [string]$TestsPath = ( Join-Path -Path $HOME -ChildPath "Maester-Tests"),

        # Update the Maester tests to the latest version from the module's install location.
        [Parameter()]
        [switch]$UpdateTests,

        # Specifies the source for the Maester module. Valid values are 'Installed' (default) and 'LocalDevelopment'.
        [Parameter()]
        [ValidateSet('Installed', 'LocalDevelopment')]
        [string]$ModuleSource = 'Installed',

        # Path to the local development version of Maester and its tests. Defaults to "$HOME\Code\Personal\Maester".
        [Parameter()]
        [string]$DevPath = ( Join-Path -Path $HOME -ChildPath "Code\Personal\Maester" ),

        # Branch to use when importing the local development version of Maester instead of the installed version. Defaults to "main".
        [Parameter()]
        [string]$DevBranch = "main",

        # Import the local development version of Maester tests instead of the installed tests.
        [Parameter()]
        [switch]$DevTests,

        # Path to save the test output files to. Defaults "$HOME\maester-results\".
        [Parameter()]
        [string]$OutputPath = ( Join-Path -Path $HOME -ChildPath "maester-results" ),

        # Do not execute Maester tests.
        [Parameter()]
        [switch]$NoInvoke,

        # Include tests that are marked as long-running.
        [Parameter()]
        [switch]$IncludeLongRunning,

        # Include tests that are marked as preview.
        [Parameter()]
        [switch]$IncludePreview
    )

    Remove-Module -Name Maester -Force -ErrorAction SilentlyContinue

    if ($UpdateModule) {
        Write-Verbose "Updating Maester module to the latest prerelease version from the PowerShell Gallery."
        try {
            Update-PSResource -Name 'Maester' -Prerelease -Force
        } catch {
            Write-Warning "Failed to update Maester module: $($_.Exception.Message)"
        }
    }

    if ($ModuleSource -eq 'LocalDevelopment') {
        Write-Verbose "Importing the local development version of Maester from $DevPath instead of the installed version."
        if (-Not (Test-Path -Path $DevPath)) {
            Write-Error "The specified DevPath '$DevPath' does not exist. Please create it or specify a different path."
            return
        }

        try {
            Write-Verbose "Switching to branch '$DevBranch' and pulling the latest changes."
            Set-Location -Path $DevPath
            git switch $DevBranch
            git pull origin $DevBranch
        } catch {
            Write-Warning "Failed to switch to branch '$DevBranch' or pull the latest changes. Please ensure the branch exists and the Git CLI is installed. $($_.Exception.Message)"
            return
        }

        $ModulePath = Join-Path -Path $DevPath -ChildPath "powershell/Maester.psm1"
        if (-Not (Test-Path -Path $ModulePath)) {
            Write-Error "The Maester module manifest was not found at '$ModulePath'. Please check the DevPath and ensure the module exists."
            return
        }
        Remove-Module -Name Maester -Force -ErrorAction SilentlyContinue
        try {
            Import-Module $ModulePath -Force
        } catch {
            Write-Error "Failed to import the Maester module from '$ModulePath'. $($_.Exception.Message)"
            return
        }
    } else {
        # Import the installed Maester module
        Import-Module -Name Maester -Force
    }

    if ($UpdateTests) {
        Write-Verbose "Updating Maester tests in path: '$TestsPath'"
        try {
            Update-MaesterTests -Path $TestsPath
        } catch {
            Write-Warning "Failed to update Maester tests: $($_.Exception.Message)"
        }
    }

    if ($DevTests) {
        $UsingTestsPath = Join-Path -Path $DevPath -ChildPath "tests"
    } else {
        $UsingTestsPath = $TestsPath
    }

    if (-not $NoInvoke) {
        Write-Verbose "Running Maester tests from '$UsingTestsPath' and saving results to '$OutputPath'"
        Invoke-Maester -Path $UsingTestsPath -OutputFolder $OutputPath -IncludeLongRunning:$IncludeLongRunning -IncludePreview:$IncludePreview
    } else {
        Write-Verbose "Skipping test invocation as -NoInvoke was specified."
    }
} # End of function Test-MaesterSuite
