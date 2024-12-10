# This is ancient. I need to rewrite this, wherever it came from!
Import-Module ActiveDirectory
Get-ADGroupMember 'SourceGroupA-sAMAccountName' | ForEach-Object {
    Add-ADGroupMember -Identity 'DestinationGroupB-sAMAccountName' -Members $_
}
