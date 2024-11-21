function Get-CertificateAuthority {
    <#
    .SYNOPSIS
    Get information about Certificate Authorities in Active Directory

    .DESCRIPTION
    This function returns a list of Certificate Authorities in Active Directory with the following properties:

      - DistinguishedName
      - CN
      - Name
      - DisplayName
      - DNSHostName
      - ADSPath
      - InstanceType
      - Flags
      - CACertificateDN
      - CACertificate
      - CertificateTemplates
      - ObjectGUID
      - ObjectClass
      - ObjectCategory
      - WhenCreated
      - WhenChanged
      - UsnChanged
      - UsnCreated

    .PARAMETER None
    This function does not accept any parameters

    .EXAMPLE
    Get-CertificateAuthority
    Returns a list of Certificate Authorities in Active Directory.

    .OUTPUTS
    System.Collections.Generic.List[System.Object]

    .NOTES
    Author: Sam Erde
    Company: Sentinel Technologies, Inc.
    Version: 0.1.0
    Modified: 2024-11-21
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Object]])]
    param (

    )

    begin {

    } # end begin

    process {
        $RootDSE = [ADSI]'LDAP://RootDSE'
        $ConfigurationNamingContext = $RootDSE.configurationNamingContext
        $LdapQuery = '(&(objectClass=pKIEnrollmentService)(objectCategory=pKIEnrollmentService))'

        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.SearchRoot = [ADSI]"LDAP://$ConfigurationNamingContext"
        $Searcher.Filter = $LdapQuery
        $Results = $Searcher.FindAll()

        $CertificateAuthorities = New-Object System.Collections.Generic.List[System.Object]
        $Results | ForEach-Object {
            $CertificateAuthorities.Add([ordered]@{
                    DistinguishedName    = $_.Properties['distinguishedname'][0]
                    CN                   = $_.Properties['cn'][0]
                    Name                 = $_.Properties['name'][0]
                    DisplayName          = $_.Properties['displayname'][0]
                    DNSHostName          = $_.Properties['dNSHostname'][0]
                    ADSPath              = $_.Properties['adspath'][0]
                    InstanceType         = $_.Properties['instancetype'][0]
                    Flags                = $_.Properties['flags'][0]
                    CACertificateDN      = $_.Properties['cacertificatedn'][0][0]
                    CACertificate        = $_.Properties['cacertificate'][0]
                    CertificateTemplates = $_.Properties['certificatetemplates'][0]
                    ObjectGUID           = $_.Properties['objectguid'][0]
                    ObjectClass          = $_.Properties['objectclass'][0]
                    ObjectCategory       = $_.Properties['objectcategory'][0]
                    WhenCreated          = $_.Properties['whencreated'][0]
                    WhenChanged          = $_.Properties['whenchanged'][0]
                    UsnChanged           = $_.Properties['usnchanged'][0]
                    UsnCreated           = $_.Properties['usncreated'][0]
                })
        }
    } # end process

    end {
        $CertificateAuthorities
    } # end end
} # end function Get-CertificateAuthority
