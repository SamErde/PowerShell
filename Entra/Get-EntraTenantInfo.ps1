function Get-EntraTenantInfo {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $DomainName
    )

    ( Invoke-WebRequest -Uri https://login.windows.net/$DomainName/.well-known/openid-configuration ).Content | ConvertFrom-Json
}
