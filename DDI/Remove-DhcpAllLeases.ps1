function Remove-DhcpAllLeases {
    [CmdletBinding(SupportsShouldProcess)]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', 'Remove-DhcpAllLeases',Justification='Removing ALL of leases.')]
    param (
        # The hostname of the DHCP server
        [Parameter(Required, Position = 0)]
        [string]
        $ComputerName
    )

    Write-Host "`nWARNING! You are about to remove all DHCP leases from the server $ComputerName." -ForegroundColor White -BackgroundColor DarkRed -NoNewLine
    Write-Host "" # Clear the colors
    $AreYouSure = Read-Host -Prompt "Enter `'yes'` to proceed or any other key to abort"
    if ($AreYouSure -ne 'yes') {
        # End the script
        break
    }

    $Scopes = Get-DhcpServerv4Scope -ComputerName $ComputerName

    foreach ($scope in $Scopes) {
        $Leases = Get-DhcpServerv4Lease -ScopeId $scope.scopeid -ComputerName $ComputerName
            foreach($lease in $leases) {
                if ($PSCmdlet.ShouldProcess($ComputerName, ("Removing all DHCP leases on $ComputerName"))) {
                    Remove-DhcpServerv4Lease -IPAddress $lease.IPAddress -ComputerName $ComputerName
                    Write-Output "Removed $($lease.IPAddress) from scope."
                } else {
                    Write-Output "WhatIf: Removing $lease from $scope."
                }
            }
    }
}
