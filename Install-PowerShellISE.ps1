<#
.SYNOPSIS
Install the Windows PowerShell ISE.

.DESCRIPTION
This script installs the Windows PowerShell ISE if it is not already. It includes a step that resets the Windows 
Automatic Update server source in the registry temporary, which may resolve errors that some people experience 
while trying to add Windows Capabilities. This was created because Out-GridView in Windows PowerShell 5.1 does not
work without the ISE installed. However, Out-GridView was rewritten and included in PowerShell 7 for Windows.

#>

#Requires -RunAsAdministrator

if ((Get-WindowsCapability -Name 'Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0' -Online).State -eq "Installed") {
    Write-Output "The Windows PowerShell ISE is already installed."
}
else {
    # Resetting the Windows Update source sometimes resolves errors when trying to add Windows capabilities
    $CurrentWUServer = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" | Select-Object -ExpandProperty UseWUServer
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0
    Restart-Service wuauserv

    try {
        Get-WindowsCapability -Name Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0 -Online | Add-WindowsCapability –Online -Verbose
    }
    catch {
        Write-Output "There was a problem adding the Windows PowerShell ISE: $error"
    }

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value $CurrentWUServer
    Restart-Service wuauserv
}
