function Test-UsernameConventionMatch {
    <#
    .SYNOPSIS
        Verifies if a username matches specific naming conventions based on AD attributes.

    .DESCRIPTION
        This function retrieves a user from Active Directory and checks if their sAMAccountName follows either
        the "initials" convention or the "FirstInitial + SurName" convention based on their GivenName and SurName.

    .PARAMETER Identity
        The identity of the AD user to check. Can be a sAMAccountName, DistinguishedName, GUID, or SID.

    .EXAMPLE
        Test-UsernameConventionMatch -Identity "jdoe"

    .EXAMPLE
        Get-ADUser -Filter {Department -eq "IT"} | Test-UsernameConventionMatch

    .OUTPUTS
        PSCustomObject containing the validation results.

    .NOTES
        Requires the ActiveDirectory module.

        TO DO: NEED TO HANDLE USERS THAT HAVE NO MIDDLE INITIAL BUT THE USERNAME IS STILL IN THE INITIALS FORMAT.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('SamAccountName', 'UserName', 'DistinguishedName')]
        [string]$Identity
    )

    begin {
        # Import the Active Directory module if not already loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
    }

    process {
        try {

            # Get the user from Active Directory
            $ADUser = Get-ADUser -Identity $Identity -Properties GivenName, SurName -ErrorAction Stop

            # Extract the necessary information
            $Username = $ADUser.SamAccountName
            $FirstName = $ADUser.GivenName
            $MiddleInitial = $ADUser.Initials
            $LastName = $ADUser.SurName

            # Validate that we have first and last names
            if ([string]::IsNullOrEmpty($FirstName) -or [string]::IsNullOrEmpty($LastName)) {
                Write-Warning "User $Identity does not have both GivenName and SurName attributes populated in AD."
                return
            }

            # Prepare the expected formats
            $Initials = ($FirstName[0] + $MiddleInitial + $LastName[0]).ToLower()
            $FirstInitialLastName = ($FirstName[0] + $LastName).ToLower()

            # Check if the username matches any of the conventions
            $MatchesInitials = $Username -eq $Initials
            $MatchesFirstInitialLastName = $Username -eq $FirstInitialLastName

            # Return the results as an object
            [PSCustomObject]@{
                Username                              = $Username
                FirstName                             = $FirstName
                LastName                              = $LastName
                MatchesInitialsConvention             = $MatchesInitials
                MatchesFirstInitialLastNameConvention = $MatchesFirstInitialLastName
                IsConventionMatch                     = $MatchesInitials -or $MatchesFirstInitialLastName
                ExpectedInitialsFormat                = $Initials
                ExpectedFirstInitLastNameFormat       = $FirstInitialLastName
            }
        } catch {
            Write-Error "Failed to process user '$Identity': $_"
        }
    }
}
