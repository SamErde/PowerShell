function Compare-FilesWithVSCode {
    <#
    .SYNOPSIS
        Opens two files in Visual Studio Code's diff viewer.

    .DESCRIPTION
        Launches Visual Studio Code with the diff view to compare two files side-by-side.
        Requires Visual Studio Code to be installed and accessible via the 'code' command.

    .PARAMETER ReferencePath
        The path to the reference file (shown on the left in diff view).

    .PARAMETER DifferencePath
        The path to the difference file (shown on the right in diff view).

    .EXAMPLE
        Compare-FilesWithVSCode -ReferencePath '~/file1.txt' -DifferencePath '~/file2.txt'
        Opens file1.txt and file2.txt in VS Code's diff viewer.

    .EXAMPLE
        Compare-FilesWithVSCode '~/original.ps1' '~/modified.ps1'
        Compares two PowerShell scripts using positional parameters.

    .NOTES
        Requires Visual Studio Code to be installed and the 'code' command available in PATH.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'Path to the reference file'
        )]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "Reference file does not exist: $_"
            }
            $true
        })]
        [string]$ReferencePath,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            HelpMessage = 'Path to the difference file'
        )]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Leaf)) {
                throw "Difference file does not exist: $_"
            }
            $true
        })]
        [string]$DifferencePath
    )

    begin {
        # Verify VS Code is available
        $CodeCommand = Get-Command -Name 'code' -ErrorAction SilentlyContinue
        if (-not $CodeCommand) {
            throw "Visual Studio Code ('code') not found. Please ensure VS Code is installed and added to PATH."
        }
    }

    process {
        try {
            # Launch VS Code with diff view
            & code --diff $ReferencePath $DifferencePath
        }
        catch {
            Write-Error "Failed to open diff view: $_"
        }
    }
}
