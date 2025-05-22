function Get-UserTeamsMembership {
    <#
    .SYNOPSIS
    Get all teams that the given user is a member of in Microsoft Teams.

    .DESCRIPTION
    This function retrieves all teams that the specified user is a member of in Microsoft Teams.
    It connects to the Microsoft Teams and Microsoft Graph services using the provided tenant ID.

    .PARAMETER UserId
    The UserID of the user whose team memberships you want to retrieve.

    .PARAMETER TenantId
    The tenant ID to connect to.

    .EXAMPLE
    Get-UserTeamsMembership -UserId jdoe@example.com -TenantId $TenantId

    Retrieves all teams that the user with UserID 'jdoe@example.com'

    #>
    [CmdletBinding()]
    param (
        # The UserID of the user whose team memberships you want to retrieve.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$UserId,

        # The tenant ID to connect to.
        [Parameter(Mandatory)]
        [string]$TenantId
    )

    begin {
        # Ensure we're connected to the required services
        try {
            Connect-MicrosoftTeams -TenantId $TenantId -ErrorAction Stop
            Connect-MgGraph -TenantId $TenantId -ErrorAction Stop
        } catch {
            Write-Error "Failed to connect to Microsoft 365 services: $_"
            return
        }
    }

    process {
        try {
            $User = Get-MgUser -UserId $UserId -ErrorAction Stop
            Get-Team -User $User.Id
        } catch {
            Write-Error "Failed to get team memberships for user '$UserId': $_"
        }
    }
}
