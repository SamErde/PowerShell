function Get-NtpClientConfig {
    <#
        .SYNOPSIS
        Get basic NTP client configuration details from Windows.

        .DESCRIPTION
        This function gets the NTP source server, source type, and last known good time for the NTP client without requiring local administrator privileges. Note: Performing a remote check does require administrative privileges on the remote computer.

        .EXAMPLE
        Get-NtpConfig

        Gets the NTP client configuration from the local host.

        .EXAMPLE
        Get-NtpClientConfig -ComputerName 'COMPUTER01'

        Gets the NTP client configuration from COMPUTER01.

        .NOTES
        Author: Sam Erde
        Version: 0.1.0
        Modified: 2024-12-04
    #>
    [CmdletBinding()]
    param (
        # The computer to query.
        [Parameter(ValueFromPipeline, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        $RegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\W32Time'
    } # end begin

    process {

        if ($ComputerName -match $env:COMPUTERNAME -or $ComputerName -eq 'localhost') {
            [PSCustomObject]@{
                Type              = (Get-ItemProperty -Path "$RegistryPath\Parameters" -Name Type).Type
                Server            = (Get-ItemProperty -Path "$RegistryPath\Parameters" -Name NtpServer).NtpServer
                LastKnownGoodTime = [datetime]::FromFileTime( (Get-ItemProperty -Path "$RegistryPath\Config" -Name LastKnownGoodTime).LastKnownGoodTime )
            }
        } else {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                [PSCustomObject]@{
                    Type              = (Get-ItemProperty -Path "$RegistryPath\Parameters" -Name Type).Type
                    Server            = (Get-ItemProperty -Path "$RegistryPath\Parameters" -Name NtpServer).NtpServer
                    LastKnownGoodTime = [datetime]::FromFileTime( (Get-ItemProperty -Path "$RegistryPath\Config" -Name LastKnownGoodTime).LastKnownGoodTime )
                }
            }
        }
    } # end process

    end {
        #
    } # end end

} # end function Get-NtpConfig
