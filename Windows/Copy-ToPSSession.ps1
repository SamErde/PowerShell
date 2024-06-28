<#
.SYNOPSIS
Copy files to a server using PowerShell remoting sessions instead of SMB.

.DESCRIPTION
A method to copy files to a server using PowerShell remoting sessions instead of SMB, 
which should be off/blocked as a best practice in secure networks.

.NOTES
The parameters below could be setup to accept objects from the pipeline.
#>

function Copy-ItemToRemote {
    [CmdletBinding()]
    param (
        [Parameter()]
            [string]$RemoteComputer,
        [Parameter()]
            [string]$SourcePath,
        [Parameter()]
            [string]$DestinationPath,
        [Parameter(Mandatory=$false)]
            $Session
    )

    if (-not $Session) {
        $Session = New-PSSession -ComputerName $RemoteComputer #-Credential
    }
    try {
        Copy-Item -Path $SourcePath -Target $DestinationPath -ToSession $Session
    }
    catch {
        $Error
    }
}
