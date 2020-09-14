function Test-Elevation {
    <#
    .Synopsis
        Get a value indicating whether the process is elevated (running as administrator or root)
    #>
    [CmdletBinding()]
    param()

    [Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown("BuiltInAdministratorsSid")
}

function Prompt {
    <#
    .Synopsis
        Set a custom prompt that shows elevated status, username, history ID, and current path, 
        followed by a > on a clean line.
    #>
    [CmdletBinding()]
    param()

    $realLASTEXITCODE = $LASTEXITCODE

    Write-Host

    if (Test-Elevation) {
      Write-Host "ELEVATED " -NoNewline -ForegroundColor Yellow
    }

    Write-Host "$ENV:USERNAME " -NoNewline -ForegroundColor White
    #Write-Host "$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow

    $HistoryId = $MyInvocation.HistoryId
    Write-Host -Object "`[$HistoryId`] " -NoNewline -ForegroundColor Cyan

    Write-Host $($(Get-Location)) -NoNewline -ForegroundColor White

    $global:LASTEXITCODE = $realLASTEXITCODE

    Write-Host ""

    return "> "
}

function Title {
  if (Test-Elevation) { 
    $Host.UI.RawUI.WindowTitle = "ELEVATED PowerShell: $($env:USERNAME) @ $($env:COMPUTERNAME)" 
  }
  if (!(Test-Elevation)) { 
    $Host.UI.RawUI.WindowTitle = "PowerShell: $($env:USERNAME) @ $($env:COMPUTERNAME)"
  }
}

Prompt
Title
