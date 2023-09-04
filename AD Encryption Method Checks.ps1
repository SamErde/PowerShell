<# Create comment based help to introduce the script.
    Find explicitly defined encryption types on your user accounts that are vulnerable to CVE-2022-37966: accounts where DES / RC4 is explicitly enabled but not AES.
    
    Need to review documentation to validate filters for desired results: 
    https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/decrypting-the-selection-of-supported-kerberos-encryption-types/ba-p/1628797
    
    Inspiration: @debugprivilege and https://support.microsoft.com/en-us/topic/kb5021131-how-to-manage-the-kerberos-protocol-changes-related-to-cve-2022-37966-fd837ac3-cdec-4e76-a6ec-86e67501407d

    Goal: find accounts using vulnerable or "less secure" encryption types, but don't depend on the ActiveDirectory module.
#>

$FilterVulnerableEncryptionTypes = '(&(objectClass=user)(msDS-supportedEncryptionTypes=7)(!(msDS-supportedEncryptionTypes=24)))'
$FilterUnspecifiedEncryptionTypes = '(&(objectClass=user)(|(!msDS-SupportedEncryptionTypes=*)(msDS-SupportedEncryptionTypes=0)))'

$Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
# Need to set max result size to get everything while accounting for the server default limit of 1000.  ::thinking::

    $PropertiesToLoad = @("distinguishedname","msds-supportedencryptiontypes","pwdlastset","useraccountcontrol","lastlogontimestamp","displayname","description")
    foreach ($item in $PropertiesToLoad) {
        [void]$Searcher.PropertiesToLoad.Add("$item")
    }

# Directly filter all users for those with vulnerable encryption types set
$Searcher.Filter = "$FilterVulnerableEncryptionTypes"
$AccountsVulnerable = $Searcher.FindAll()
Write-Output "There are $($AccountsVulnerable.Count) vulnerable accounts using RC4 or DES encryption."

# Directory filter all users for those that are not vulnerable (RC4/DES) but also are not yet using AES
$Searcher.Filter = "$FilterUnspecifiedEncryptionTypes"
$AccountsNotRequiringAES = $Searcher.FindAll()
Write-Output "There are $($AccountsNotRequiringAES.Count) accounts that are not yet enforcing AES encryption."


# A better way to find both: 
$Searcher.Filter = "(objectClass=user)"
$AllUsers = $Searcher.FindAll()

$AllUsers | Group-Object msds-supportedencryptiontypes






$UserEncryptionTypes = Get-ADUser -Properties msDS-SupportedEncryptionTypes,KerberosEncryptionType,CanonicalName -Filter *

$UserEncryptionTypes | Group-Object 'msDS-SupportedEncryptionTypes'

$UserEncryptionTypes.Where({$_.'msDS-SupportedEncryptionTypes' -eq $null -or $_.'msDS-SupportedEncryptionTypes' -eq '0'}) | `
    Select-Object *,@{N="Path";E={ ((($_.CanonicalName).Split('/')) | Select-Object -SkipLast 1) -join '/' } } | `
        Group-Object Path -NoElement | Sort-Object Name | Format-Table Count,Name -AutoSize

