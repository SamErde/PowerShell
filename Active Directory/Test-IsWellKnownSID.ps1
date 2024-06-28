function Test-IsWellKnownSid {
    <#
        .SYNOPSIS
            Check if a SID is a well-known SID.

        .DESCRIPTION
            Check if a SID or a SID string is a well-known SID. Returns a Boolean response.

        .PARAMETER SID
            The SID to test. This can be a SecurityIdentifier object or a string that will be converted into a SID object.

        .EXAMPLE
            Test-IsWellKnownSid -SID (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-10"))

        .EXAMPLE
            Test-IsWellKnownSid -SID "S-1-5-10"

        .OUTPUTS
            System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # Accepts a SecurityIdentifier object or a string that will be converted into a SID object.
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        $SID
    )

    begin {
        [bool]$IsWellKnownSID = $false
    }

    process {
        # If the SID paramemter is a [string] type, convert it to a SecurityIdentifier object.
        if ( $SID -is [string] ) {
            try {
                $SID = New-Object System.Security.Principal.SecurityIdentifier($SID)
            } catch {
                Write-Error "Failed to convert `"$SID`" to a SecurityIdentifier object."
                break
            }
        }

        if ( $SID.ToString() -eq "S-1-5-10" ) {
            $IsWellKnownSID = $true
        }

        # Compare the SID to all the well-known SID types.
        foreach ( $type in [Enum]::GetNames( [System.Security.Principal.WellKnownSidType] ) ) {
            if ( $SID.IsWellKnown($type) ) {
                $IsWellKnownSID = $true
            }
        }
    }

    end {
        $IsWellKnownSID
    }
}
