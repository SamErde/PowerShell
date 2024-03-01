function Get-EnvironmentVariable {
    <#
        .SYNOPSIS
            Retrieves the value of an environment variable.

        .DESCRIPTION
            The Get-EnvironmentVariable function retrieves the value of the specified environment variable
            or displays all environment variables.

        .PARAMETER Name
            The name of the environment variable to retrieve.

        .EXAMPLE
            Get-EnvironmentVariable -Name "PATH"
            Retrieves the value of the "PATH" environment variable.

        .OUTPUTS
            System.String
            The value of the environment variable.

        .NOTES
            Variable names are case-sensitive on Linux and macOS, but not on Windows.

            Why is 'Target' used by .NET instead of the familiar 'Scope' parameter name? @IISResetMe (Mathias R. Jessen) explains:
            "Scope" would imply some sort of integrated hierarchy of env variables - that's not really the case.
            Target=Process translates to kernel32!GetEnvironmentVariable (which then in turn reads the PEB from
            the calling process), whereas Target={User,Machine} causes a registry lookup against environment
            data in either HKCU or HKLM.

            The relevant sources for the User and Machine targets are in the registry at: 
            - HKEY_CURRENT_USER\Environment
            - HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
        .LINK
            https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables
    #>
    [Alias("gev")]
    [Outputs([System.String])]
    [CmdletBinding()]
    param (
        # The name of the environment variable to retrieve. If not specified, all environment variables are returned.
        [Parameter()]
        [string]$Variable,

        # The target of the environment variable to retrieve. Defaults to Machine. (Process, User, or Machine)
        [Parameter()]
        [System.EnvironmentVariableTarget]
        $Target = [System.EnvironmentVariableTarget]::Machine,

        # Switch to show environment variables in all target scopes.
        [Parameter()]
        [switch]
        $All
    )
    
    begin {
        
    }
    
    process {
        if ( $PSBoundParameters.Contains($Variable) ) {
            [Environment]::GetEnvironmentVariable($Variable, $Target)
        } elseif (-not $PSBoundParameters.Contains($All) ) {
            [Environment]::GetEnvironmentVariables()
        }

        if ($All) {
            Write-Output "Process Environment Variables:"
            [Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process)
            Write-Output "User Environment Variables:"
            [Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)
            Write-Output "Machine Environment Variables:"
            [Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
        }
    }
    
    end {
        
    }
}
