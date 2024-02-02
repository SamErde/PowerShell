function Update-SysInternals {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$DestinationPath = $PSScriptRoot
    )
    
    begin {
        Write-Host $PSScriptRoot
        [string]$Uri = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
    }

    process {
        Write-Host "Downloading SysInternals to $DestinationPath..." -BackgroundColor DarkCyan -ForegroundColor Green
        # Use BITS to download sysinternals to the specified path or the current folder
        Start-BitsTransfer -Source $Uri -Destination $DestinationPath -Description "Downloading SysInternals from live.sysinternals.com" -DisplayName "Update-SysInternals" -Verbose -Asynchronous
        Get-BitsTransfer
        # Set the registry value to automatically accept the SysInternals EULA
        if (!(Test-Path "HKCU:\Software\SysInternals")) {
            New-Item -Path "HKCU:\Software\SysInternals" -ItemType Directory -Force
        }
        Set-ItemProperty -Path HKCU:\Software\SysInternals -Name EulaAccepted -Value 1 -Type DWORD
        
        Get-BitsTransfer
    }
    
    end {
        Write-Host "Have fun!" -BackgroundColor DarkCyan -ForegroundColor Green
    }
}
