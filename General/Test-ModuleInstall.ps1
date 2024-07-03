function Test-ModuleInstall {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Name of the module to check and install.
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name
    )

    if (Get-Command -Module $Name -ErrorAction SilentlyContinue) {
        Write-Output "$Name module is already installed."
        return
    }

    # Check all installed modules.
    if (Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue) {
        Write-Output "The `'$Name`' module is already installed."
        return
    }

    # Check if running with administrator rights before installing.
    $isAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdministrator) {
        Write-Output "Please run as an administrator to install the `'$Name`' module."
        return
    }

    # Ask user if they want to install the module
    if ($PSCmdlet.ShouldProcess("$Name module", 'Install')) {
        Write-Verbose "Installing `'$Name`' module..."
        Install-Module -Name "$Name" -Scope CurrentUser -Force -AllowClobber -Verbose
    }
}
