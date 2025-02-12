<#
.SYNOPSIS
    Install PowerShell as a .NET global tool, which does not require Administrator privileges.
.DESCRIPTION
    This script installs PowerShell as a .NET global tool, which does not require Administrator privileges. It begins by
    downloading the required .NET Tool install script, which is then used to install PowerShell.
.NOTES
    Author: Sam Erde (@SamErde)
    Date: 2025-02-12
.LINK
    https://github.com/SamErde/PowerShell/General
#>

# Download the .NET CLI install script if it is not found.
if ( (Get-Command -Name 'dotnet' -ErrorAction SilentlyContinue) ) {
    Write-Verbose "dotnet is already installed."
} else {
    $DownloadPath = Join-Path -Path $env:TEMP -ChildPath 'dotnet-install.ps1'
    try {
        Invoke-WebRequest 'https://dot.net/v1/dotnet-install.ps1' -OutFile $DownloadPath
        Unblock-File -Path $DownloadPath
    } catch {
        Write-Error "Failed to download dotnet-install.ps1 to '$DownloadPath'."
        throw $_
    }

    # Install the dotnet tool. The script installs the latest LTS release by default.
    # The current stable release is required for PowerShell 7.5, which depends on .NET 9.
    # Need to add a check for the appropriate version of .NET.
    try {
        .$DownloadPath -InstallDir '~/.dotnet' -Channel 'STS' # use of 'Current' is deprecated.
    } catch {
        throw $_
    }

}

dotnet dev-certs https --trust

# Install PowerShell and add $HOME\.dotnet\tools to the PATH.
# Need to add error handling for when the required version of .NET is missing.
try {
    dotnet tool install --global PowerShell
    $env:PATH += ';' + [System.IO.Path]::Combine($HOME, '.dotnet', 'tools')
} catch {
    throw $_
}

# Clean up.
Remove-Variable -Name DownloadPath
if (Test-Path -Path DownloadPath) {
    Remove-Item -Path $DownloadPath -Confirm:$false
}
