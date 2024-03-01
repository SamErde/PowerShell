function Get-EnvironmentVariables {
    [Alias('gev')]
    [CmdletBinding()]
    param (
        # The name of the environment variable to retrieve. If not specified, all environment variables are returned.
        [Parameter()]
        [string]$Variable
    )
    
    begin {
        
    }
    
    process {
        if ($Variable) {
            [Environment]::GetEnvironmentVariable($Variable)
        } else {
            [Environment]::GetEnvironmentVariables()
        }
    }
    
    end {
        
    }
}
