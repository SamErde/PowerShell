<# Base PowerShell Profile
.SYNOPSIS
    A cross-platform PowerShell profile that sets useful defaults, imports common modules, and provides a custom prompt.

.DESCRIPTION
    This PowerShell profile works in Windows PowerShell and PowerShell on Windows, Linux, and macOS. It features:

    - Detection of the operating system, PowerShell edition, and host environment.
    - Imports useful modules based on the environment.
    - Sets default options for PSReadLine.
    - Provides a custom prompt that shows admin status, command history, command duration, and current path.
    - Uses Oh My Posh for a rich prompt or a standalone custom prompt when OMP is not installed.
    - Returns a hash table with environment information for use in terminal operations.

.NOTES
    Author   : Sam Erde
    Modified : 2025-09-30
    GitHub   : https://github.com/SamErde/PowerShell
#>

#region Environment Information
function Get-EnvironmentInfo {
    # Get environment information for the current session. Returns a hash table.
    [CmdletBinding()]

    param ()

    $IsAdmin = if (($PSVersionTable.PSVersion.Major -le 5) -or $IsWindows) {
        $CurrentUser = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
        $CurrentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } else {
        # Must be Linux or macOS, so use the id util. Root has userid of 0.
        0 -eq (id -u)
    }

    if ($PSVersionTable.PSEdition -eq 'Desktop' -or $PSVersionTable.PSVersion -lt '6.0.0') {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', 'PSProfileBase.ps1', Justification = 'This variable was only introduced in PowerShell 6, so no conflict is introduced in Windows PowerShell.')]
        $IsWindows = $true
        if ($Host.Name -eq 'Windows PowerShell ISE Host') {
            $IsPowerShellISE = $true
        } else {
            $IsPowerShellISE = $false
        }
    } else {
        $IsPowerShellISE = $false
        $IsPowerShellCore = $true
    }

    return New-Object -TypeName PSCustomObject -Property @{
        IsAdmin           = $IsAdmin
        IsLinux           = $IsLinux
        IsMacOS           = $IsMacOS
        IsWindows         = $IsWindows
        IsPowerShellCore  = $IsPowerShellCore
        PSEdition         = $PSVersionTable.PSEdition
        IsPowerShellISE   = $IsPowerShellISE
        IsVSCode          = if ($psEditor) { $true } else { $false }
        IsWindowsTerminal = if ($env:WT_SESSION) { $true } else { $false }
    }
} # end function Get-EnvironmentInfo

$EnvironmentInfo = Get-EnvironmentInfo
#endregion Environment Information

#region ImportModules
# Define modules to import based on OS and PowerShell edition.
$Modules = @{
    AllEditions    = @('posh-git', 'Terminal-Icons')
    CoreWindows    = @('CompletionPredictor', 'Microsoft.WinGet.CommandNotFound')
    CoreNonWindows = @('CompletionPredictor', 'Microsoft.PowerShell.UnixTabCompletion')
}

# Import all cross-platform modules.
$Modules.AllEditions | Import-Module

# Import modules for PowerShell on Windows.
if ($EnvironmentInfo.PSEdition -eq 'Core' -and $IsWindows) {
    $Modules.CoreWindows | Import-Module
}

if ($EnvironmentInfo.IsVSCode) {
    Import-Module 'EditorServicesCommandSuite'
}

# Import modules for PowerShell on Linux or macOS.
if ($IsLinux -or $IsMacOS) {
    $Modules.CoreNonWindows | Import-Module
}
#endregion ImportModules

#region Default Settings
#region Default Settings: PSReadLine
$PSReadLineOptions = @{
    HistoryNoDuplicates           = $true
    HistorySearchCursorMovesToEnd = $true
}
Set-PSReadLineOption @PSReadLineOptions

# Do not write to history file if command was less than 4 characters. Credit: Sean Wheeler.
$global:__DefaultHistoryHandler = (Get-PSReadLineOption).AddToHistoryHandler
Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$Line)
    $DefaultResult = $global:__defaultHistoryHandler.Invoke($Line)
    if ($DefaultResult -eq 'MemoryAndFile') {
        if ($Line.Length -gt 3 -and $Line[0] -ne ' ' -and $Line[-1] -ne ';') {
            return 'MemoryAndFile'
        } else {
            return 'MemoryOnly'
        }
    }
    return $DefaultResult
} # end PSReadLine History Handler
#endregion Default Settings: PSReadLine

# Set the working location to the Code folder in my home directory. Default to my home directory if the Code folder does not exist.
if (Test-Path -Path (Join-Path -Path $HOME -ChildPath 'Code') -PathType Container -ErrorAction SilentlyContinue) {
    Set-Location (Join-Path -Path $HOME -ChildPath 'Code')
} else {
    Set-Location -Path $HOME
}
# Set UTF-8 as the default encoding for all input and output operations.
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
#endregion Default Settings

#region Version Specific Settings
if ($EnvironmentInfo.PSEdition -eq 'Desktop') {
    # Windows PowerShell Default Settings
    $PSDefaultParameterValues = @{
        'ConvertTo-Csv:NoTypeInformation' = $true
        'ConvertTo-Xml:NoTypeInformation' = $true
        'Export-Csv:NoTypeInformation'    = $true
        'Format-[WT]*:AutoSize'           = $true
        '*:Encoding'                      = 'utf8'
        'Out-Default:OutVariable'         = 'LastOutput'
    }

    Set-PSReadLineOption -PredictionViewStyle ListView -PredictionSource History
    # ProgressPreference can dramatically slow down some scripts in Windows PowerShell. Only enable it when needed.
    Set-Variable -Name ProgressPreference -Value 'SilentlyContinue'

} else {
    # PowerShell [Core] Default Settings
    $PSDefaultParameterValues = @{
        'Format-[WT]*:AutoSize'   = $true
        'Out-Default:OutVariable' = 'LastOutput'
    }

    Set-PSReadLineOption -PredictionViewStyle ListView -PredictionSource HistoryAndPlugin

    <# Detect if connected to a remote session over SSH by checking the value of the $env:SSH_CLIENT environment
       variables. If true, set the default value of the AsOSC52 parameter, which allows you to set the clipboard of
       the local machine when connected to a remote session over SSH. Requires PowerShell 7.4. #>
    $PSDefaultParameterValues['Set-Clipboard:AsOSC52'] = $env:SSH_CLIENT
}
#endregion Version Specific Settings

#region Version Specific Prompt
if ($IsPowerShellISE -or (-not (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue))) {
    # Known Issue: Due to load order and support issues, this prompt does not render properly in the PowerShell ISE when it is dot sourced from another profile. It does work when placed directly in the ISE profile or run manually.
    # Use a custom prompt without Oh My Posh
    $FolderGlyph = [System.Char]::ConvertFromUtf32([System.Convert]::ToInt32('1F4C1', 16))
    # Use a red lightning bolt to indicate admin status or a white silhouette for non-admin.
    if ($IsAdmin) {
        $AdminStatus = "$([System.Char]::ConvertFromUtf32([System.Convert]::ToInt32('26A1', 16)))" # Lightning bolt
        $AdminStatusColor = 'Red'
    } else {
        $AdminStatus = "$([System.Char]::ConvertFromUtf32([System.Convert]::ToInt32('1F464', 16)))" # User silhouette
        $AdminStatusColor = 'White'
    }
    # Custom prompt function that shows admin status, command ID, command duration, and path.
    function Prompt {
        $LastCommand = Get-History -Count 1 -ErrorAction SilentlyContinue
        Write-Host "$AdminStatus " -ForegroundColor "$AdminStatusColor" -NoNewline
        Write-Host "[$($LastCommand.Id +1)] $([math]::Ceiling($LastCommand.Duration.TotalMilliseconds))ms " -NoNewline -ForegroundColor White
        Write-Host "$FolderGlyph $($PWD.ToString() -ireplace [regex]::Escape($HOME),'~')" -ForegroundColor Yellow
        Write-Host '>' -NoNewline -ForegroundColor White
        return ' '
    }

} else {
    # Initialize Oh My Posh prompt when not in PowerShell ISE. To do: Move to a dot file location in home folder and automatically download from GitHub if missing.
    oh-my-posh init pwsh --config "$HOME/.ohmyposh/comply.omp.json" | Invoke-Expression
}
#endregion Version Specific Prompt
