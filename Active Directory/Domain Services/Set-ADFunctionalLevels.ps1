Set-ADFunctionalLevels {

    # DRAFT - WORK IN PROGRESS

    [CmdletBinding()]
    param(
        # Domain functional level
        [Parameter()]
        [System.DirectoryServices.ActiveDirectory.DomainMode]
        $DomainFunctionalLevel,

        # Forest functional level
        [Parameter()]
        [System.DirectoryServices.ActiveDirectory.DomainMode]
        $ForestFunctionalLevel
    )

    Import-Module ActiveDirectory

    if ($PSBoundParameters.ContainsKey('DomainFunctionalLevel') -and -not $PSBoundParameters.ContainsKey('ForestFunctionalLevel')) {
        # Domain Functional Level
        $PDCe = Get-ADDomainController -Discover -Service PrimaryDC
        Get-ADDomain -Identity $PDCe.Domain | Select-Object domainMode, DistinguishedName
        Set-ADDomainMode -Identity $PDCe.Domain -Server $PDCe.HostName[0] -DomainMode $DomainFunctionalLevel -WhatIf
        Get-ADDomain -Identity $PDCe.Domain | Select-Object domainMode, DistinguishedName
    }

    if ($PSBoundParameters.ContainsKey('ForestFunctionalLevel') -and -not $PSBoundParameters.ContainsKey('DomainFunctionalLevel')) {
        # Forest Functional Level
        $Forest = Get-ADForest
        $Forest.ForestMode
        Set-ADForestMode -Identity $Forest -Server $Forest.SchemaMaster -ForestMode $ForestFunctionalLevel -WhatIf
            (Get-ADForest).ForestMode
    }
}
