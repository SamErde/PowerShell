function Get-DhcpOptionUsed {
    <#
    .SYNOPSIS
    Check for the usage of specific DHCP option IDs in any context on a DHCP server.

    .DESCRIPTION
    Check for the usage of specific DHCP option IDs in any context on a DHCP server, including DHCP server options, scope options, and reservation options.

    .PARAMETER Server
    The hostname of a DHCP server to inspect.

    .EXAMPLE
    Get-DhcpOptionUsed -Server 'dhcpserver1'

    This example checks the server options, scope options, and reservation options on the DHCP server named 'dhcpserver1'.

    .NOTES
    While this currently checks for options related to DNS/name servers and NTP servers, it could be expanded with parameters to provide groups of checks for different types of options.
    #>
    [CmdletBinding()]
    param (
        # DHCP Server Name
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server = $env:COMPUTERNAME
    )

    begin {
        # Get the server's hostname if localhost is specified.
        if ($Server -eq 'localhost') {
            $Server = $env:COMPUTERNAME
        }

        # Define the options to check
        $DhcpOptionList = [ordered]@{
            6  = 'DNS Servers'
            42 = 'NTP Servers'
            44 = 'WINS/NBNS Servers'
        }
        $OptionsToCheck = $DhcpOptionList.Keys
    } # end begin block

    process {
        # Check if the $Server is listed in the objects returned by Get-DhcpServerInDC.
        $DhcpServers = Get-DhcpServerInDC
        if ($DhcpServers.DnsName -notmatch $Server) {
            Write-Warning -Message "The server `'$Server`' is not an authorized DHCP server in the domain."
            return
        }

        # Verify that the server is reachable.
        try {
            $null = Test-NetConnection -ComputerName $Server -Count 1 -ErrorAction Stop
        } catch {
            Write-Error "Unable to connect to server: $Server"
            return
        }

        # Get all IPv4 DHCP server options and check the options set on each.
        Write-Host 'Checking DHCP Server Options....' -ForegroundColor Green -BackgroundColor Black
        $ServerOptions = Get-DhcpServerv4OptionValue
        foreach ($option in $ServerOptions) {
            if ($OptionsToCheck -contains $option.OptionId) {
                Write-Host ".... > Server has option $($option.OptionId) set." -ForegroundColor Magenta -BackgroundColor Black
            }
        } # end foreach server option

        # Get all IPv4 DHCP scopes and check the options set on each.
        Write-Host 'Checking DHCP Scope Options....' -ForegroundColor Green -BackgroundColor Black
        $v4Scopes = Get-DhcpServerv4Scope
        foreach ($scope in $v4Scopes) {
            # Check scope options first.
            Write-Host "....Checking Scope: $($scope.ScopeId)" -ForegroundColor Yellow -BackgroundColor Black
            $ScopeOptions = $null
            $ScopeOptions = Get-DhcpServerv4OptionValue -ScopeId $scope.ScopeId
            foreach ($option in $ScopeOptions) {
                if ($optionsToCheck -contains $option.OptionId) {
                    Write-Host ".... > Scope $($scope.ScopeId) has option $($option.OptionId) set." -ForegroundColor Magenta -BackgroundColor Black
                }
            } # end foreach scope option

            # Check reservation options.
            $v4Reservations = Get-DhcpServerv4Reservation -ScopeId $scope.ScopeId
            foreach ($reservation in $v4Reservations) {
                Write-Host "....Checking Reservation: $($reservation.IPAddress)" -ForegroundColor Yellow -BackgroundColor Black
                $ReservationOptions = $null
                $ReservationOptions = Get-DhcpServerv4OptionValue -ScopeId $scope.ScopeId -ReservedIP $reservation.IPAddress
                foreach ($option in $ReservationOptions) {
                    if ($optionsToCheck -contains $option.OptionId) {
                        Write-Output ".... > Reservation $($reservation.IPAddress) in scope $($scope.ScopeId) has option $($option.OptionId) set."
                    }
                } # end foreach reservation option
            } # end foreach reservation
        } # end foreach scope

    } # end process block

    end {
        Write-Host "Finished checking DHCP options on $Server." -ForegroundColor Green -BackgroundColor Black
    } # end end block
}
