function Get-PathDepth {
    <#
    .SYNOPSIS
    Get the depth of a path relative to a base directory.

    .DESCRIPTION
    Get the depth of a directory or a file from the base directory that you specify. If no base directory is specified,
    the root of the current directory (eg: 'C:\')is used.

    .PARAMETER BaseFolder
    The base folder to count depth from. Defaults to the root of the current directory.

    .PARAMETER CheckPath
    The path to calculate the depth of from the base path.

    .EXAMPLE
    Get-PathDepth -CheckPath 'C:\Users\Alice\Documents\MyFile.txt'

    This example calculates the depth of the file 'MyFile.txt' from the root of the C: drive and returns 3.

    .EXAMPLE
    Get-PathDepth -BaseFolder 'C:\Users' -CheckPath 'C:\Users\Alice\Documents\MyFile.txt'

    This example calculates the depth of the file 'MyFile.txt' from the 'C:\Users' directory and returns 2.

    .NOTES
    Author: Sam Erde
    Company: Sentinel Technologies, Inc
    Created: 2025-03-17
    Version: 1.0.0
    #>
    param (
        # The base folder to count depth from. Defaults to the root of the current directory.
        [Parameter(HelpMessage = 'The base folder to count depth from. Defaults to the root of the current directory.')]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$BaseFolder = [System.IO.Path]::GetPathRoot($PWD),

        # The path to calculate the depth of from the base path.
        [Parameter(Mandatory, HelpMessage = 'The path to calculate the depth of from the base path.')]
        [ValidateScript({ Test-Path (Resolve-Path -Path $_) })]
        [string]$CheckPath
    )

    if ( -not ($CheckPath -like "*$BaseFolder*") ) {
        Write-Error -Message 'The CheckPath must be a subdirectory of the BaseFolder.' -ErrorAction Stop
        #break
    }

    $DirectorySeparator = [System.IO.Path]::DirectorySeparatorChar

    # Ensure the paths are absolute paths and remove trailing directory separators.
    $BaseFolder = ([System.IO.Path]::GetFullPath((Resolve-Path -Path $BaseFolder))).TrimEnd($DirectorySeparator)
    $CheckPath = ([System.IO.Path]::GetDirectoryName((Resolve-Path -Path $CheckPath))).TrimEnd($DirectorySeparator)

    # Remove the base folder path from the file path to get the relative path with no leading slash.
    $RelativePath = $CheckPath.Replace("$BaseFolder", '').TrimStart($DirectorySeparator)

    # Split the relative path into individual folder components and count them to get the depth.
    $PathComponents = $RelativePath.Split($DirectorySeparator)
    [int16]$PathComponents.Count
} # end function Get-PathDepth
