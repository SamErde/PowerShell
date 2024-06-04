function Get-InputProperties {
    <#
        .SYNOPSIS
            Check an input object to see if it contains specific properties.
        .DESCRIPTION
            This script checks an input object to see if it contains specific properties.
            This could be useful when validating inputs such as CSV columns or custom objects.

            THIS CONCEPT AND POTENTIAL USE CASE IS NOT COMPLETE
    #>
    [CmdletBinding()]
    param (
        $InputObjectObject
    )

    begin {
        # Create a sample input object if none is provided
        if (-not $PSBoundParameters.Contains('Input') ) {
            $InputObject = [PSCustomObject]@{
                GivenName   = 'Sam'
                MiddleName  = ''
                SurName     = 'Erde'
                DisplayName = 'Sam Erde'
                Suffix      = ''
            }
        }
    }

    process {

        if ([bool]$InputObject.PSObject.Properties["GivenName"]) {
            $GivenName = $InputObject.GivenName;
        }
        if ([bool]$InputObject.PSObject.Properties["SurName"]) {
            $SurName = $InputObject.SurName;
        }
        if ([bool]$InputObject.PSObject.Properties["Nickname"]) {
            $Nickname = $InputObject.Nickname;
        } else {
            "The property 'Nickname' was not present."
        }
    }
    
    end {
        Out-Null $GivenName $SurName $Nickname
    }
}
