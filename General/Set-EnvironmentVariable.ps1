function Set-EnvironmentVariable {
    [Alias('sev')]
    [CmdletBinding()]
    param (
        # The name of the environment variable to set.
        [Parameter(Mandatory)]
        [string]$Name,

        # The value of environment variable to set.
        [Parameter(Mandatory)]
        [string]
        $Value,

        # The target of the environment variable to set.
        [Parameter()]
        [System.EnvironmentVariableTarget]
        $Target
    )

    begin {

    }

    process {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Target)
    }

    end {

    }
}
