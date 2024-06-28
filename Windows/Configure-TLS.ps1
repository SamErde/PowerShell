# README
# This script will add or remove TLS 1.0 and 1.1 functionality in the registry of a Windows Server,
# and configures .Net packages to use modern TLS.
# It also ensures 1.2 functionality is enabled.
# TLS version functionality only takes effect after a reboot, so you will need to restart the server after executing this function.
#
# In order to execute this script, call it from a PowerShell Prompt, and use any one of the following commands:
# Enable1.0 Enable1.1 Enable.Net EnableBoth Disable1.0 Disable1.1 Disable.Net DisableBoth
# 
# Most of the time you will want to Enable/Disable both, but if a system is not working with both disabled it certainly is better
# to enable just 1.1 and leave 1.0 disabled (though, not THAT much better) when possible.
#
# Please note you can use Tab to autocomplete the script name from the PowerShell prompt, so start typing "configu" then hit
# Tab and it will auto format your command to execute the script, then add the desired configuration.
#
# Some examples:
# .\Configure-TLS.ps1 DisableBoth
# .\Configure-TLS.ps1 Enable1.1
#
# Configure-TLS script version 1.1
#
# Changelog:
# 1.1:
# Added .Net TLS Configurations.
# 
# Written by Alex Cunningham
# Please reach out with any questions!
#
param (
    [Parameter(Mandatory=$true)][string]$Action
)

# Inform user of script progress
Write-Host "Setting up variables, registry paths, and enabling TLS 1.2..." -ForegroundColor Green -BackgroundColor Black
    
# Set up a variable to access SCHANNEL\Protocols
$TLSLoc = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"

# Set up .Net registry locations, for native apps (32 on 32, 64 on 64) or WOW (32 on 64)
$Net2Native = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727"
$Net4Native = "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
$Net2WOW = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v2.0.50727"
$Net4WOW = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"

# Ensure TLS entries exist for TLS 1.0
If (!(Test-Path "$TLSLoc\TLS 1.0\Server\")) { New-Item "$TLSLoc\TLS 1.0\Server\" -Force }
If (!(Test-Path "$TLSLoc\TLS 1.0\Client\")) { New-Item "$TLSLoc\TLS 1.0\Client\" -Force }

# Ensure TLS entries exist for TLS 1.1
If (!(Test-Path "$TLSLoc\TLS 1.1\Server\")) { New-Item "$TLSLoc\TLS 1.1\Server\" -Force }
If (!(Test-Path "$TLSLoc\TLS 1.1\Client\")) { New-Item "$TLSLoc\TLS 1.1\Client\" -Force }

# Ensure TLS entries exist for TLS 1.2
If (!(Test-Path "$TLSLoc\TLS 1.2\Server\")) { New-Item "$TLSLoc\TLS 1.2\Server\" -Force }
If (!(Test-Path "$TLSLoc\TLS 1.2\Client\")) { New-Item "$TLSLoc\TLS 1.2\Client\" -Force }

# Turn on TLS 1.2 (this should be handled by GPO, but as a precaution we will force enabling them)
Set-ItemProperty -Path "$TLSLoc\TLS 1.2\Server\" -Name "Enabled" -Value 1
Set-ItemProperty -Path "$TLSLoc\TLS 1.2\Server\" -Name "DisabledByDefault" -Value 0
Set-ItemProperty -Path "$TLSLoc\TLS 1.2\Client\" -Name "Enabled" -Value 1
Set-ItemProperty -Path "$TLSLoc\TLS 1.2\Client\" -Name "DisabledByDefault" -Value 0

# Run Enable1.0 block
If (($Action -eq "Enable1.0") -or ($Action -eq "EnableBoth")) {
    # Informational
    Write-Host "Enabling TLS 1.0..." -ForegroundColor Green -BackgroundColor Black
        
    # Configure TLS 1.0 to Enabled
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Server\" -Name "Enabled" -Value 1
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Server\" -Name "DisabledByDefault" -Value 0
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Client\" -Name "Enabled" -Value 1
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Client\" -Name "DisabledByDefault" -Value 0
        
    # Informational
    Write-Host "TLS 1.0 is enabled." -ForegroundColor Green -BackgroundColor Black
}

# Run Enable1.1 block
If (($Action -eq "Enable1.1") -or ($Action -eq "EnableBoth")) {
    # Informational
    Write-Host "Enabling TLS 1.1..." -ForegroundColor Green -BackgroundColor Black
        
    # Configure TLS 1.1 to Enabled
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Server\" -Name "Enabled" -Value 1
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Server\" -Name "DisabledByDefault" -Value 0
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Client\" -Name "Enabled" -Value 1
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Client\" -Name "DisabledByDefault" -Value 0
        
    # Informational
    Write-Host "TLS 1.1 is enabled." -ForegroundColor Green -BackgroundColor Black
}

#Run Disable1.0 block
If (($Action -eq "Disable1.0") -or ($Action -eq "DisableBoth")) {
    # Informational
    Write-Host "Disabling TLS 1.0..." -ForegroundColor Green -BackgroundColor Black
        
    # Configure TLS 1.0 to Disabled
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Server\" -Name "Enabled" -Value 0
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Server\" -Name "DisabledByDefault" -Value 1
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Client\" -Name "Enabled" -Value 0
    Set-ItemProperty -Path "$TLSLoc\TLS 1.0\Client\" -Name "DisabledByDefault" -Value 1

    # Informational
    Write-Host "TLS 1.0 is disabled." -ForegroundColor Green -BackgroundColor Black
}

#Run Disable1.1 block
If (($Action -eq "Disable1.1") -or ($Action -eq "DisableBoth")) {
    # Informational
    Write-Host "Disabling TLS 1.1..." -ForegroundColor Green -BackgroundColor Black
            
    # Configure TLS 1.1 to Disabled
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Server\" -Name "Enabled" -Value 0
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Server\" -Name "DisabledByDefault" -Value 1
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Client\" -Name "Enabled" -Value 0
    Set-ItemProperty -Path "$TLSLoc\TLS 1.1\Client\" -Name "DisabledByDefault" -Value 1

    # Informational
    Write-Host "TLS 1.1 is disabled." -ForegroundColor Green -BackgroundColor Black
}

# .Net configurations are OS and App architecture dependent, so need to check for native or foreign keys

#Run Enable.Net block
If (($Action -eq "Enable.Net") -or ($Action -eq "EnableBoth")) {
    # Informational
    Write-Host "Enabling old .Net TLS" -ForegroundColor Green -BackgroundColor Black
            
    # Configure .Net to allow old TLS Versions
    If (Test-Path $Net2Native) {
        Set-ItemProperty -Path $Net2Native -Name "SystemDefaultTlsVersions" -Value 0
        Set-ItemProperty -Path $Net2Native -Name "SchUseStrongCrypto" -Value 0
    }

    If (Test-Path $Net4Native) {
        Set-ItemProperty -Path $Net4Native -Name "SystemDefaultTlsVersions" -Value 0
        Set-ItemProperty -Path $Net4Native -Name "SchUseStrongCrypto" -Value 0
    }

    If (Test-Path $Net2WOW) {
        Set-ItemProperty -Path $Net2WOW -Name "SystemDefaultTlsVersions" -Value 0
        Set-ItemProperty -Path $Net2WOW -Name "SchUseStrongCrypto" -Value 0
    }

    If (Test-Path $Net4WOW) {
        Set-ItemProperty -Path $Net4WOW -Name "SystemDefaultTlsVersions" -Value 0
        Set-ItemProperty -Path $Net4WOW -Name "SchUseStrongCrypto" -Value 0
    }

    # Informational
    Write-Host ".Net now allows old TLS" -ForegroundColor Green -BackgroundColor Black
}

#Run Disable.Net block
If (($Action -eq "Disable.Net") -or ($Action -eq "DisableBoth")) {
    # Informational
    Write-Host "Disabling old .Net TLS" -ForegroundColor Green -BackgroundColor Black
            
    # Configure .Net to allow old TLS Versions
    If (Test-Path $Net2Native) {
        Set-ItemProperty -Path $Net2Native -Name "SystemDefaultTlsVersions" -Value 1
        Set-ItemProperty -Path $Net2Native -Name "SchUseStrongCrypto" -Value 1
    }

    If (Test-Path $Net4Native) {
        Set-ItemProperty -Path $Net4Native -Name "SystemDefaultTlsVersions" -Value 1
        Set-ItemProperty -Path $Net4Native -Name "SchUseStrongCrypto" -Value 1
    }

    If (Test-Path $Net2WOW) {
        Set-ItemProperty -Path $Net2WOW -Name "SystemDefaultTlsVersions" -Value 1
        Set-ItemProperty -Path $Net2WOW -Name "SchUseStrongCrypto" -Value 1
    }

    If (Test-Path $Net4WOW) {
        Set-ItemProperty -Path $Net4WOW -Name "SystemDefaultTlsVersions" -Value 1
        Set-ItemProperty -Path $Net4WOW -Name "SchUseStrongCrypto" -Value 1
    }

    # Informational
    Write-Host ".Net now blocks old TLS" -ForegroundColor Green -BackgroundColor Black
}

Write-Host "Changes complete, please restart the server to ingest changes." -ForegroundColor Green -BackgroundColor Black
