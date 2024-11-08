function Reset-CitrixWorkspace {
    <#
    .SYNOPSIS
    Reset the Citrix Receiver or Workspace App

    .DESCRIPTION
    This script resets the Citrix Receiver or Workspace app and all of the current user's Citrix shortcuts.

    .EXAMPLE
    Reset-CitrixWorkspace

    .NOTES
    Author: Sam Erde, Sentinel Technologies
    Version: 0.0.3
    Modified: 2024-11-7

    .LINK
    https://support.citrix.com/s/article/CTX140149-how-to-reset-receiver-or-citrix-workspace-app-using-the-command-line

    #>
    [CmdletBinding(SupportsShouldProcess = $false)]
    param ()

    # Define static variables
    $ShortcutFolder = "${env:APPDATA}\Microsoft\Windows\Start Menu\Programs\Citrix"
    $CleanupToolPath = "${env:ProgramFiles(x86)}\Citrix\ICA Client\SelfServicePlugin\CleanUp.exe"
    $SelfServicePath = "${env:ProgramFiles(x86)}\Citrix\ICA Client\SelfServicePlugin\SelfService.exe"

    # Run the Citrix Clean-up Tool
    if (Test-Path -Path $CleanupToolPath -PathType Leaf) {
        Start-Process -FilePath $CleanupToolPath -ArgumentList '/silent -cleanUser'
    } else {
        Write-Error -Message "The Cleanup tool was not found at $CleanupToolPath."
        return
    }

    # Remove the Citrix shortcut folder in the current user's start menu
    try {
        Remove-Item -Path $ShortcutFolder -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Warning -Message "Failed to remove the Citrix shortcut folder in the user's start menu.`n$_"
        return
    }

    # Wait for shortcut folder to come back. Time out after 30 seconds if not.
    $StartTime = Get-Date
    while (-not (Test-Path $ShortcutFolder)) {
        $StepTime = (Get-Date)
        if ( ($StepTime - $StartTime).Seconds -ge 30 ) {
            Write-Warning -Message 'Timed out while waiting for the Citrix folder to be recrated in the Start Menu.'
            break
        }
        Write-Information -MessageData 'Waiting for the folder to be recreated...' -InformationAction Continue
        Start-Sleep 5
    }

    # Poll for new shortcuts after waiting 5 seconds
    Start-Sleep 5

    # Restart the SelfService executable and contact the server to refresh application details. This step should recreate shortcuts
    Start-Process -FilePath $SelfServicePath -ArgumentList '-poll'

}

Reset-CitrixWorkspace
