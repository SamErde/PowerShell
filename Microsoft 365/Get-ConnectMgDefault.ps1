function Get-ConnectMgDefault {
    <#
    .SYNOPSIS
    Returns the default Microsoft Graph authentication record stored in the current user's .mg folder.

    .DESCRIPTION
    Loads the Microsoft Graph CLI authentication record from "$HOME/.mg/mg.authrecord.json" and presents it as a custom object. This helps you inspect which account and tenant are used by default when connecting with Microsoft Graph.

    .EXAMPLE
    Get-ConnectMgDefault

    Retrieves the default Microsoft Graph authentication record.

    .EXAMPLE
    Get-ConnectMgDefault | Select-Object Account, TenantId, Scopes

    Returns only the most commonly reviewed fields from the authentication record.

    .INPUTS
    None. You cannot pipe objects to this cmdlet.

    .OUTPUTS
    PSCustomObject. Returns the contents of 'mg.authrecord.json' as a custom object, or $null if the file cannot be read.

    .NOTES
    Author:   Sam Erde, Sentinel Technologies Inc.
    Modified: 2025 Dec 15
    #>
    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param ()

    try {
        $DotMgPath = Join-Path -Path (Resolve-Path -Path $HOME).Path -ChildPath '.mg'
        $AuthRecordPath = Join-Path -Path $DotMgPath -ChildPath 'mg.authrecord.json'
        Get-Content -Path $AuthRecordPath | ConvertFrom-Json
    } catch {
        Write-Warning "Unable to read '$AuthRecordPath'. $($_.Exception.Message)"
        return $null
    }
}
