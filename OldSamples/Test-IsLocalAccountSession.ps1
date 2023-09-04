function Test-IsLocalAccountSession {
<#
.SYNOPSIS
    Tests if the current session is running under a local user account or a domain account.
.DESCRIPTION
    This function returns True if the current session is a local user or False if it is a domain user.
.EXAMPLE
    Test-IsLocalAccountSession
.EXAMPLE
    if ( (Test-IsLocalAccountSession) ) { Write-Host "You are running this script under a local account." -ForeGroundColor Yellow }
#>
    [CmdletBinding()]

    $CurrentSID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $LocalSIDs = (Get-LocalUser).SID.Value
    if ($CurrentSID -in $LocalSIDs) {
        Return $true
    }
}

# This could be one function that accepts either a name or a SID as a parameter, but using SIDs just makes sense!
function Test-IsLocalAccountByName {
    [CmdletBinding()]

    #Get the current username
    $User = [Security.Principal.WindowsIdentity]::GetCurrent().Name

    # Check if the user name contains a backslash (\)
    if ($User -match '\\') {
        # Check if the domain name is equal to the computer name
        if ( ($User.split('\'))[0] -eq ($env:computername) ) {
        # The current session is running under a local user account
        Return $true
        }
        else {
            # Domain account
            Return $false
        }
    }
    else {
        # The current session is running in a local user account without a domain prefix
        Return $true
    }
}