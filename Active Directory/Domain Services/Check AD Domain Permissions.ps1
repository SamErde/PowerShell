<#
  The idea for this script was based a sample script provided by Trimarc at
  https://www.hub.trimarcsecurity.com/post/mitigating-exchange-permission-paths-to-domain-admins-in-active-directory.

  See also: https://www.hub.trimarcsecurity.com/post/securing-active-directory-performing-an-active-directory-security-review
#>

# Customizable Variables:
$DomainRootPermissionsReportDir = '.\Reports'
$DomainRootPermissionsReportName = 'DomainRootPermissionsReport.csv'

# Script Variables
$ADDomain = (Get-ADDomain).DnsRoot
$ConfigurationContext = $((Get-ADRootDSE).ConfigurationNamingContext)
$DomainTopLevelObjectDN = (Get-ADDomain $ADDomain).DistinguishedName
$GUID = ''
$DomainRootPermissionsReportPath = $DomainRootPermissionsReportDir + '\' + $ADDomain + '-' + $DomainRootPermissionsReportName

function Get-PermissionName {
    param (
        [string]$GUID
    )
    # Look for the GUID in the Extended-Rights of the ControlAccessRight class
    $ExtendedRightsName = ( (Get-ADObject -SearchBase "CN=Extended-Rights,$ConfigurationContext" -LDAPFilter "(&(ObjectClass=ControlAccessRight)(RightsGUID=$GUID))") ).Name
    if ( $ExtendedRightsName ) {
        Return $ExtendedRightsName
    }
    # If the GUID is not found in Extended-Rights, look for it in the SchemaNamingContext:
    else {
        $SchemaRightsName = ( (Get-ADObject -SearchBase (Get-ADRootDSE).SchemaNamingContext -LDAPFilter "(SchemaIDGUID=$GUID)" -Properties Name, SchemaIDGUID) ).Name
        Return $SchemaRightsName
    }
}

# Create the directory if it does not already exist
if ( !(Test-Path $DomainRootPermissionsReportDir) ) {
    New-Item -type Directory -Path $DomainRootPermissionsReportDir
}

# Get the details of the domain root permissions.
$DomainRootPermissions = Get-ADObject -Identity $DomainTopLevelObjectDN -Properties * | Select-Object -ExpandProperty nTSecurityDescriptor | Select-Object -ExpandProperty Access

# Export the permissions and details to the CSV file.
$DomainRootPermissions | Select-Object IdentityReference, ActiveDirectoryRights, AccessControlType, IsInherited, InheritanceType, `
    InheritedObjectType, ObjectFlags, InheritanceFlags, PropagationFlags, @{N = 'Type'; E = { Get-PermissionName $_.ObjectType } } `
| Export-Csv $DomainRootPermissionsReportPath -NoTypeInfo

# Display the essential details.
$DomainRootPermissions | Select-Object IdentityReference, ActiveDirectoryRights, AccessControlType, IsInherited | Sort-Object ActiveDirectoryRights, IdentityReference

Write-Output `n"$ADDomain Domain Permission Report saved to $DomainRootPermissionsReportPath"
