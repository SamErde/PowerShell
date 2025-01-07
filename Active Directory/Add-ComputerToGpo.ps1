function Add-ComputerToGPO {
    <#
    .SYNOPSIS
    Add a computer a GPO's security filtering list (GpoApply permission).

    .DESCRIPTION
    Add a computer a GPO's security filtering list (GpoApply permission).

    .PARAMETER ComputerName
    The hostname of the computer to add to the GPO's security filtering list (GpoApply permission).

    .PARAMETER GPOName
    Name of the GPO to add the computer to.

    .PARAMETER Domain
    Name of the domain where the GPO exists.

    .EXAMPLE
    Add-ComputerToGPO -ComputerName 'Computer1'

    .EXAMPLE
    'Computer1' | Add-ComputerToGPO

    .NOTES
    Author: Sam Erde
    Company: Sentinel Technologies, Inc
    Version: 1.0.0
    Modified: 2025-01-07

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The hostname of the domain controller to add to the decommissioning GPO
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'The hostname of the computer to add to the GPO.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName,

        # Name of the GPO to add the computer to.
        [Parameter(Mandatory)]
        [string]
        $GPOName,

        # Name of the domain where the GPO exists.
        [Parameter()]
        [string]
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
    )

    begin {
        # Get the GPO object.
        try {
            $GPO = Get-GPO -Name $GPOName -Domain $Domain
        } catch {
            throw "GPO '$GPOName' not found in domain '$Domain'.`n $_"
        }
        # Show the current permissions for computer objects on the GPO.
        $GPOComputerPermissions = Get-GPPermission -Guid $GPO.Id -DomainName $Domain -TargetType Computer -All |
            Where-Object { $_.Trustee.SidType -eq 'Computer' }
        $GPOComputerPermissions | Select-Object -Property Permission, Inherited -ExpandProperty Trustee |
            Format-Table Name, SidType, Permission, Inherited -AutoSize
    }

    process {
        # Add the domain controller to the GPO's security filtering list by granting it 'Apply' permissions.
        if ($PSCmdlet.ShouldProcess('Target', 'Operation')) {
            Set-GPPermission -WhatIf -Guid $GPO.Id -Domain $Domain -TargetName $ComputerName -PermissionLevel GpoApply -TargetType Computer
        }
    }

    end {
        # Show the updated permissions for computer objects on the GPO.
        $GPOComputerPermissions = Get-GPPermission -Guid $GPO.Id -DomainName $Domain -TargetType Computer -All |
            Where-Object { $_.Trustee.SidType -eq 'Computer' }
        $GPOComputerPermissions | Select-Object -Property Permission, Inherited -ExpandProperty Trustee |
            Format-Table Name, SidType, Permission, Inherited -AutoSize
    }
}
