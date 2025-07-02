$PSRepository = 'PSGallery'

$RequiredResource = @{

    'platyPS'                        = @{
        Repository = $PSRepository
    }
    'Pester'                         = @{
        Repository = $PSRepository
    }
    'Microsoft.Graph.Users'          = @{
        Repository = $PSRepository
    }
    'Microsoft.Graph.Authentication' = @{
        Repository = $PSRepository
        Version    = '2.25.0'
    }
    'Az.Accounts'                    = @{
        Repository = 'MAR'
    }

}

Install-PSResource -RequiredResource $RequiredResource
