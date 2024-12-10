<#
    .SYNOPSIS
    Plumb the depths of Active Directory organizational units to find the deepst.

    .DESCRIPTION
    Find the deepst OUs in Active Directory and summarize how many OUs are at each depth.

    .LINK
    https://social.technet.microsoft.com/wiki/contents/articles/5312.active-directory-characters-to-escape.aspx

    .LINK
    https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/naming-conventions-for-computer-domain-site-ou
#>

function Get-OrganizationalUnitDepth {
    [CmdletBinding()]
    [Alias('Get-OUDepth')]
    param (
        [parameter(ValueFromPipeline = $true, ParameterSetName = 'UserSpecified')]
        # Allow the user to specify an OU to fathom (from the pipeline)
        $OrganizationalUnit,

        [parameter()]
        # Show the OUs at the deepest level of the OU hierarchy
        [switch]$Deepest,

        [parameter()]
        # Just show a summary with the number of OUs at each depth
        [switch]$Summary
    )

    begin {
        Import-Module ActiveDirectory

        # if ((-not($Deepest)) -and (-not($Summary))) { $Summary = $true }
    }

    process {
        # Get the specified OU or get all OUs if none is specified.
        if ($OrganizationalUnit) {
            $OUs = $OrganizationalUnit | Get-ADOrganizationalUnit -Properties CanonicalName
        } else {
            $OUs = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName
        }

        <#
            Create Summary of Organizational Unit Depths
            Group OUs by the count of forward slashes in their canonical names.

                NOTE: Grouping by CanonicalName is easier to work with than DistinguishedName because the entire domain
                name is in its own segment, whereas DNs can have an unknown number of DC segments that represent the
                FQDN of the domain.

            "Name" isn't a helpful column heading for each depth group, so I change that to "Depth" with Select-Object.
        #>
        $OUDepths = $OUs | Group-Object { ([regex]::Matches($_.CanonicalName, '/')).Count } |
            Select-Object @{Name = 'Depth'; Expression = { $_.Name } }, @{Name = 'OU Count'; Expression = { $_.Count } }, Group |
                Sort-Object Depth

        <# Get the Deepest OUs:

            Select the last group from the sorted list to get the deepest OUs.
            Use Tee-Object to drop the highest depth value into a variable while continuing the pipeline.
            The final the final Select-Object statement pulls the OU objects from that grouped object.
        #>
        if ($Deepest) {
            # The downside to counting by commas in the DistinguishedName is you need to account for an unknown of DC segments in the domain name.
            $DeepestOUs = $OUDepths | Select-Object -Last 1 | Tee-Object -Variable DeepestGroup | Select-Object -ExpandProperty Group
            $DeepestDepth = $DeepestGroup.Depth

            # Create an OutputMessage that can be used for host output, logging, or reporting.
            $OutputMessage = "The deepest OUs are $DeepestDepth levels deep:`n`n$(($DeepestOUs.CanonicalName) -join("`n"))"
            # Send the deepest OUs to the pipeline.
            $Output = $DeepestOUs
        }

        if ($Summary) {
            # Create an OutputMessage that can be used for host output, logging, or reporting.
            $OutputMessage = "The deepest OUs are $DeepestDepth levels deep:`n`n$(($DeepestOUs.CanonicalName) -join("`n"))"

            $Output = $OUDepths
        }
    }

    end {
        Write-Information -MessageData $OutputMessage -InformationAction Continue
        $Output
    }
}
