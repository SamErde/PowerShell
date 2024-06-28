# This is ancient. I need to rewrite this, wherever it came from!
Import-Module ActiveDirectory
Get-AdGroupMember "SourceGroupA-sAMAccountName" | %{Add-ADGroupMember -Identity "DestinationGroupB-sAMAccountName" -Members $_}
