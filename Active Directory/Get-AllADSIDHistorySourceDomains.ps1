function Get-AllADSIDHistorySourceDomains {
    <#
    .SYNOPSIS
    Get a list of source domains from all Active Directory objects that have SID history.

    .DESCRIPTION
    This function gets all Active Directory objects that have SID history and returns a list of source domain SIDs.

    .EXAMPLE
    Get-AllAdSidHistorySourceDomains

    .NOTES
    Author: Sam Erde, Sentinel Technologies, Inc.
    Version: 0.0.1
    Modified: 2024-11-14
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Verbose -Message 'Importing ActiveDirectory module.'
            Import-Module ActiveDirectory
            Write-Verbose -Message '------------------------------'
            Write-Verbose -Message "Beginning ${MyInvocation.InvocationName}..."
        }

        $SIDHistoryList = [ordered]@{}
        $DomainSIDs = New-Object -TypeName System.Collections.Generic.List[System.String]
    } # end begin

    process {
        # Get all ActiveDirectory objects that have SID history.
        $ADObjectsWithSIDHistory = Get-ADObject -Filter { SIDHistory -like '*' } -Properties SIDHistory | Select-Object * -ExpandProperty SIDHistory

        foreach ($object in $ADObjectsWithSIDHistory) {
            # Create a hash table of DistinguishedName and SIDHistory for each object.
            $SIDHistoryList.Add($object.DistinguishedName, $object.SIDHistory)
            # Create a de-duplicated list of source domain SIDs from the SIDHistory attribute of each object.
            $DomainSIDs.Add( $($object.SIDHistory.Substring(0, $SID.LastIndexOf('-'))) )
        }
    } # end process

    end {

    } # end end

} # end function
