# Create a hash table of all permission class and sub-class types from the AD schema.
$ObjectTypeGUID = @{}
(Get-ADObject -SearchBase (Get-ADRootDSE).SchemaNamingContext -LDAPFilter '(SchemaIDGUID=*)' -Properties Name, SchemaIDGUID).
ForEach({ $ObjectTypeGUID.Add([GUID]$_.SchemaIDGUID, $_.Name) })

(Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)" -LDAPFilter '(ObjectClass=ControlAccessRight)' -Properties Name, RightsGUID).ForEach({ $ObjectTypeGUID.Add([GUID]$_.RightsGUID, $_.Name) })
$ObjectTypeGUID | Format-Table -AutoSize

# Example:
$ObjectTypeGUID[[GUID]'00299570-246d-11d0-a768-00aa006e0529']


function Get-NameForGUID {
    # Portions from http://blog.wobl.it/2016/04/active-directory-guid-to-friendly-name-using-just-powershell/
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
        [guid]$guid,
        [string]$ForestDNSName
    )
    Begin {
        IF (!$ForestDNSName)
        { $ForestDNSName = (Get-ADForest $ForestDNSName).Name }

        IF ($ForestDNSName -notlike '*=*')
        { $ForestDNSNameDN = "DC=$($ForestDNSName.replace('.', ',DC='))" }

        $ExtendedRightGUIDs = "LDAP://cn=Extended-Rights,cn=configuration,$ForestDNSNameDN"
        $PropertyGUIDs = "LDAP://cn=schema,cn=configuration,$ForestDNSNameDN"
    }
    Process {
        If ($guid -eq '00000000-0000-0000-0000-000000000000') {
            Return 'All'
        } Else {
            $rightsGuid = $guid
            $property = 'cn'
            $SearchAdsi = ([ADSISEARCHER]"(rightsGuid=$rightsGuid)")
            $SearchAdsi.SearchRoot = $ExtendedRightGUIDs
            $SearchAdsi.SearchScope = 'OneLevel'
            $SearchAdsiRes = $SearchAdsi.FindOne()
            If ($SearchAdsiRes) {
                Return $SearchAdsiRes.Properties[$property]
            } Else {
                $SchemaGuid = $guid
                $SchemaByteString = '\' + ((([guid]$SchemaGuid).ToByteArray() | ForEach-Object { $_.ToString('x2') }) -Join '\')
                $property = 'ldapDisplayName'
                $SearchAdsi = ([ADSISEARCHER]"(schemaIDGUID=$SchemaByteString)")
                $SearchAdsi.SearchRoot = $PropertyGUIDs
                $SearchAdsi.SearchScope = 'OneLevel'
                $SearchAdsiRes = $SearchAdsi.FindOne()
                If ($SearchAdsiRes) {
                    Return $SearchAdsiRes.Properties[$property]
                } Else {
                    Write-Host -f Yellow $guid
                    Return $guid.ToString()
                }
            }
        }
    }
}
