function Enable-ADRecycleBin {
    <#
    .SYNOPSIS
    Enable the Active Directory Recycle Bin
    .DESCRIPTION
    Enable the Active Directory recycle bin for the specified domain after confirming the required functional level.
    #>
    [CmdletBinding()]
    param (
        # The domain in which to enable the AD Recycle Bin
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Domain
    )

    begin {
        if ( ((Get-ADForest).ForestMode) -ge (Get-ADOptionalFeature -Identity 'Recycle Bin Feature').RequiredForestMode ) {
            Write-Verbose "[OK] $Domain meets the minimum required forest functional level."
        } else {
            Write-Information -InformationAction Continue -MessageData "The Active Directory recycle bin feature requires the forest functional level to be at least 'WindowsServer2008R2'. Please raise the FFL before continuing."
            return
        }
    }

    process {
        if (Get-ADOptionalFeature -Identity 'Recycle Bin Feature') {
            Write-Output "The Recycle Bin Feature is already enabled in $Domain."
        } else {
            try {
                Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $Domain
                Write-Output "The Recycle Bin Feature has been enabled for $Domain."
            } catch {
                $_
            }
        } # end if
    } # end process
    
    end {
        
    }
}
