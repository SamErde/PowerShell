Import-Module ActiveDirectory
[array]$ADDomainTrusts = (Get-ADObject -Filter {ObjectClass -eq "trustedDomain"}).Name
[array]$NetBIOSDomainNames = @()

foreach ($trust in $ADDomainTrusts)
{
    $trustedDNSDomainName = $trust
    $NetBIOSDomainNames += ((Get-ADDomain $trustedDNSDomainName | Select-Object NetBIOSName)| Out-String).Trim()
}

$NetBIOSDomainNames

<# Or using this:
  $TrustedDomains = @{}           
  $TrustedDomains += Get-ADObject -Filter {ObjectClass -eq "trustedDomain"} -Properties * |
      Select-Object @{ Name = 'NetBIOSName'; Expr = { $_.FlatName } },@{ Name = 'DNSName'; Expr = { $_.Name } },$TrustedDomains

  #foreach ($Domain in $TrustedDomains) {
  #  @{ Name = 'Server'; Expr = { (Get-ADDomainController -Discover -ForceDiscover -Writable -Service ADWS -DomainName $_.Name).Hostname[0] } }
  #}
#>
