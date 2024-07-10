$ReceiveConnectors = (Get-ExchangeServer | Get-ReceiveConnector).Where({$_.Enabled -eq $true}) | Sort-Object Name,Identity
$ExternalRelays = @()
foreach ($rc in $ReceiveConnectors) {
  $dn = $rc.DistinguishedName
  if (Get-ADPermission -Identity $dn -User "NT AUTHORITY\ANONYMOUS LOGON" | Where-Object {$_.ExtendedRights.RawIdentity -eq "MS-Exch-SMTP-Accept-Any-Recipient"}) {
    $ExternalRelays += $rc
  }
}

$ExternalRelays | Select-Object Name,Server,Enabled -Unique
