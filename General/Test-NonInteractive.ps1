Function Test-InteractiveSession {
    [CmdletBinding()]
    [OutputType([bool])]
    Param()

    Process {
        # Check if we're running in a non-interactive environment
        if ([Environment]::UserInteractive -and -not ([Environment]::GetCommandLineArgs() -like '-NonInteractive*')) {
            # Check for various CI/CD environments
            $ciEnvironments = @(
                # GitHub Actions
                $env:GITHUB_ACTIONS -eq 'true',

                # GitLab CI
                $env:GITLAB_CI -eq 'true',

                # Azure DevOps
                $env:TF_BUILD -eq 'true',

                # Bitbucket Pipelines
                $null -ne $env:BITBUCKET_BUILD_NUMBER,

                # Jenkins
                $null -ne $env:JENKINS_URL,

                # CircleCI
                $env:CIRCLECI -eq 'true',

                # Travis CI
                $env:TRAVIS -eq 'true',

                # TeamCity
                $null -ne $env:TEAMCITY_VERSION
            )

            # Check for container environment
            $containerEnvironments = @(
                # Check for Docker
                (Test-Path -Path '/.dockerenv'),
                # Check for common container environment variables
                $env:KUBERNETES_SERVICE_HOST -ne $null,
                # Check for Windows container
                $env:CONTAINER -eq 'true'
            )

            # Return false if any CI/CD or container condition is true
            if ($ciEnvironments -contains $true -or $containerEnvironments -contains $true) {
                return $false
            }

            return $true
        }

        return $false
    }
}

Function Invoke-InteractivePrompt {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$DefaultResponse = '',

        [Parameter(Mandatory = $false)]
        [switch]$ShowEnvironmentInfo
    )

    Process {
        if (Test-InteractiveSession) {
            $response = Read-Host -Prompt $Message
            if ([string]::IsNullOrEmpty($response)) {
                return $DefaultResponse
            }
            return $response
        } else {
            $environmentInfo = Get-ExecutionEnvironment
            if ($ShowEnvironmentInfo) {
                Write-Verbose "Running in $($environmentInfo.Type) environment: $($environmentInfo.Name)"
            }
            Write-Verbose "Using default response: $DefaultResponse"
            return $DefaultResponse
        }
    }
}

Function Get-ExecutionEnvironment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param()

    Process {
        $environmentInfo = [PSCustomObject]@{
            Type = 'Unknown'
            Name = 'Unknown'
        }

        # Check for CI/CD environments
        if ($env:GITHUB_ACTIONS -eq 'true') {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'GitHub Actions'
        } elseif ($env:GITLAB_CI -eq 'true') {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'GitLab CI'
        } elseif ($env:TF_BUILD -eq 'true') {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'Azure DevOps'
        } elseif ($null -ne $env:BITBUCKET_BUILD_NUMBER) {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'Bitbucket Pipelines'
        } elseif ($null -ne $env:JENKINS_URL) {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'Jenkins'
        } elseif ($env:CIRCLECI -eq 'true') {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'CircleCI'
        } elseif ($env:TRAVIS -eq 'true') {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'Travis CI'
        } elseif ($null -ne $env:TEAMCITY_VERSION) {
            $environmentInfo.Type = 'CI/CD'
            $environmentInfo.Name = 'TeamCity'
        }
        # Check for container environments
        elseif (Test-Path -Path '/.dockerenv') {
            $environmentInfo.Type = 'Container'
            $environmentInfo.Name = 'Docker'
        } elseif ($null -ne $env:KUBERNETES_SERVICE_HOST) {
            $environmentInfo.Type = 'Container'
            $environmentInfo.Name = 'Kubernetes'
        } elseif ($env:CONTAINER -eq 'true') {
            $environmentInfo.Type = 'Container'
            $environmentInfo.Name = 'Windows Container'
        } elseif (-not [Environment]::UserInteractive -or [Environment]::GetCommandLineArgs() -like '-NonInteractive*') {
            $environmentInfo.Type = 'Non-interactive'
            $environmentInfo.Name = 'PowerShell'
        } else {
            $environmentInfo.Type = 'Interactive'
            $environmentInfo.Name = 'PowerShell'
        }

        return $environmentInfo
    }
}

# Example usage
$answer = Invoke-InteractivePrompt -Message 'Do you want to continue? (Y/N)' -DefaultResponse 'Y' -ShowEnvironmentInfo -Verbose
Write-Host "You chose: $answer"
