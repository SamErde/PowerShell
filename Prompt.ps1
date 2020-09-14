function Test-Elevation {
    <#
    .Synopsis
        Get a value indicating whether the process is elevated (running as administrator or root)
    #>
    [CmdletBinding()]
    param()

    [Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown("BuiltInAdministratorsSid")
}

function prompt {
    <#
    .Synopsis
        Set a custom prompt that shows elevated status, username, history ID, and current path, 
        followed by a > on a clean line.
    #>
    [CmdletBinding()]
    param()

    $realLASTEXITCODE = $LASTEXITCODE

    Write-Host

    if (Test-Elevation) {  # Use different username if elevated
        Write-Host "ELEVATED " -NoNewline -ForegroundColor Yellow
	$Host.UI.RawUI.WindowTitle = "ELEVATED: $($env:USERNAME) @ $($env:COMPUTERNAME)"
    }

    Write-Host "$ENV:USERNAME " -NoNewline -ForegroundColor White
    $Host.UI.RawUI.WindowTitle = "$($env:USERNAME) @ $($env:COMPUTERNAME)"
    #Write-Host "$ENV:COMPUTERNAME" -NoNewline -ForegroundColor Yellow

    $HistoryId = $MyInvocation.HistoryId
    Write-Host -Object "`[$HistoryId`] " -NoNewline -ForegroundColor Cyan

    Write-Host $($(Get-Location)) -NoNewline -ForegroundColor White

    $global:LASTEXITCODE = $realLASTEXITCODE

    Write-Host ""

    return "> "
}
