function Get-DomainSubdomains {
    <#
    .SYNOPSIS
    Discover sub-domains in a domain.

    .DESCRIPTION
    This function uses the VirusTotal API to discover subdomains in a given domain namespace.

    .PARAMETER Domain
    The domain to check for subdomains.

    .EXAMPLE
    Get-DomainSubdomains -Domain 'example.com'

    .NOTES
    This requires a VirusTotal API key.

    #>
    [CmdletBinding()]
    param (
        # The domain to discover subdomains in
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]
        $Domain,

        # Your VirusTotal API key. (Need to make this more secure, but it's a working POC.)
        [Parameter(Position = 1)]
        $VtApiKey
    )

    begin {

    }

    process {
        $IrmParams = @{
            Uri     = "https://www.virustotal.com/api/v3/domains/$Domain/subdomains"
            Method  = 'GET'
            Headers = @{
                'X-ApiKey'     = $VtApiKey
                'Content-Type' = 'application/json'
            }
        }
        $Subdomains = ( (Invoke-RestMethod @IrmParams) | ConvertFrom-Json).data
        $Subdomains.id

        <# Output 👀
            elections.x.com
            transparency-staging.x.com
            about-dev.x.com
            careers-dev.x.com
            engineering.x.com
            gdpr-dev.x.com
            insights.x.com
            legal-dev.x.com
            marketing-dev.x.com
            partners-dev.x.com
        #>

    }

    end {

    }
}
