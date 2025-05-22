function Set-ADUserUPNSuffix {
    [CmdletBinding()]
    param(
        # The user principal name (UPN) to set the new UPN suffix for. This can be a single UPN or an array of UPNs. This parameter accepts pipeline input from objects that have the UserPrincipalName property.
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$UserPrincipalName,

        # The new UPN suffix to set (do not include the '@' symbol).
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$NewUPNSuffix
    )

    begin {

        Start-Transcript -Path "$PSScriptRoot\Set-ADUserUPNSuffix.log" -Append -ErrorAction SilentlyContinue

        # Stop the script if the Active Directory module is not available.
        Import-Module ActiveDirectory -Verbose:$false -ErrorAction Stop
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Error 'Active Directory module is not available. Please ensure it is installed and imported.'
            return
        }

        # Remove the '@' symbol from the new UPN suffix if it was included.
        if ($NewUPNSuffix.StartsWith('@')) {
            $NewUPNSuffix = $NewUPNSuffix.Substring(1)
        }

        Write-Information -MessageData "Setting UPN suffix to '$NewUPNSuffix' for $($UserPrincipalName.Count) user(s)." -InformationAction Continue
    }

    process {

        foreach ($ThisUPN in $UserPrincipalName) {
            # Check if the user exists
            $User = Get-ADUser -Filter { UserPrincipalName -eq $ThisUPN } -ErrorAction SilentlyContinue
            if (-not $User) {
                Write-Error "A user with the UPN '$ThisUPN' not found."
                continue
            }

            # Set the new UPN suffix
            try {
                Set-ADUser -Identity $User -UserPrincipalName ($User.UserPrincipalName -replace '@.*$', "@$NewUPNSuffix") -Verbose
                Write-Host "Successfully updated UPN for user '$ThisUPN' to '$($User.UserPrincipalName -replace '@.*$', "@$NewUPNSuffix")'." -ForegroundColor Yellow
            } catch {
                Write-Error "Failed to update UPN for user '$ThisUPN': $_"
            }
        }

    }

    end {
        Stop-Transcript -ErrorAction SilentlyContinue
        Write-Information -MessageData "Finished setting UPN suffix to '$NewUPNSuffix' for $($UserPrincipalName.Count) user(s)." -InformationAction Continue
        Write-Information -MessageData "Log file created at '$PSScriptRoot\Set-ADUserUPNSuffix.log'." -InformationAction Continue

        # Remove the variables used in the script
        Remove-Variable -Name UserPrincipalName, NewUPNSuffix, ThisUPN, User -Verbose:$false -ErrorAction SilentlyContinue
    }
}
