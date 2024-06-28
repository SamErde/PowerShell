# Export the Active Directory schema to an LDIF file
# with two flavors:

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
$Schema = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]::GetCurrentSchema()

$RootDSE = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
$RootDSE = Get-ADRootDSE

$SchemaPath = "LDAP://CN=Schema,$($Domain.GetDirectoryEntry().distinguishedName)"
$SchemaPath = $RootDSE.schemaNamingContext

# Example using LDAP
$Schema.GetDirectoryEntry().psbase.Invoke("Dump", "$SchemaPath", "schema.ldf")

# Example using LDIFDE
ldifde.exe -f schema.ldf -s localhost -t 3268 -d "CN=Schema,CN=Configuration,DC=contoso,DC=com" -p subtree -r "(objectClass=*)" -l "objectClass,cn,attributeID,attributeSyntax,omSyntax"
