function Get-OUDetails {
    <#
    .SYNOPSIS
        Get advanced details about an organizational unit (OU) in Active Directory.
    .DESCRIPTION
        THIS IS STILL A CONCEPT WORK IN PROGRESS
    
    .NOTES
        The Test-BlockInheritence, Test-IsCriticalSystemObject, and Test-IsHiddenOU functions were all created because
        I would rather display an explicit value (eg: $false) than a null that implies $false. Likewise, I prefer to
        display a $true or $false rather than 1 or a 0.
    #>
    [CmdletBinding()]
    [OutputType([Array])]
    param (
    )
    
    Import-Module ActiveDirectory

    $OUs = Get-ADOrganizationalUnit -Filter * -Properties CanonicalName, gPOptions, isCriticalSystemObject, showInAdvancedViewOnly | Sort-Object CanonicalName
    foreach ($OU in $OUs) {

        [array]$OUDetails += [PSCustomObject]@{
            Name                    = $OU.Name
            DistinguishedName       = $OU.DistinguishedName
            CanonicalName           = $OU.CanonicalName
            Parent                  = Get-ParentOU $OU
            Child                   = Get-ChildOU $OU
            BlockInheritance        = Test-BlockInheritence $OU
            CriticalLocation        = Test-IsCriticalSystemObject $OU
            ShowInAdvancedViewOnly  = Test-IsHiddenOU $OU
        }
    }

    # Return the OUDetails array as the result of this function
    $OUDetails
}

function Get-ParentOU {
    # Get the parent organizational unit of an OU in Active Directory
    [CmdletBinding()]
    param (
        [Parameter()]
        $OrganizationalUnit
    )

    $DN = $OrganizationalUnit.DistinguishedName
    $ParentDN = ($DN.Replace("OU=$($OrganizationalUnit.Name),",''))

    if ($ParentDN -notlike "DC=*") {
        $ParentOU = Get-ADOrganizationalUnit -Identity "$ParentDN" -Properties CanonicalName
    } else {
        $ParentOU = $null
    }

    $ParentOU
}

function Get-ChildOU {
    # List the child OUs for an organizational unit in Active Directory
    [CmdletBinding()]
    [OutputType([Array])]
    param (
        [Parameter()]
        $OrganizationalUnit
    )

    $DN = $OrganizationalUnit.DistinguishedName
    $ChildOU = [array](Get-ADOrganizationalUnit -Filter * -SearchBase $DN -SearchScope OneLevel -Properties CanonicalName)

    $ChildOU
}

function Test-BlockInheritence {
    # Check if Block Inheritence is set on an organizational unit in Active Directory
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter()]
        $OrganizationalUnit
    )

    if ($OU.gPOptions -eq 1) {
        $true
    } else {
        $false
    }
}

function Test-IsCriticalSystemObject {
    # Check if the OU is flagged as a critical system object, which indicates that it is a default location for new AD objects.
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter()]
        $OrganizationalUnit
    )

    if ($OrganizationalUnit.isCriticalSystemObject) {
        $true
    } else {
        $false
    }
}

function Test-IsHiddenOU {
    # Check if the OU is shown in advanced view only, and hidden from the standard view in ADUC.
    [CmdletBinding()]
    [OutputType([Boolean])]
    param (
        [Parameter()]
        $OrganizationalUnit
    )

    if ($OrganizationalUnit.showInAdvancedViewOnly) {
        $true
    } else {
        $false
    }
}
