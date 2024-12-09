# Get a list of all Entra Applications and the most recent interactive sign-in for each
Connect-MgGraph -Scopes AuditLog.Read.All

Get-MgApplication -All |
    ForEach-Object {
        $x = Get-MgAuditLogSignIn -Filter "appId eq '$($_.AppId)'" -Top 1 -OrderBy 'createdDateTime desc'
        [pscustomobject]@{Id = $_.Id; DisplayName = $_.DisplayName; LastSignIn = $x.CreatedDateTime }
    }
