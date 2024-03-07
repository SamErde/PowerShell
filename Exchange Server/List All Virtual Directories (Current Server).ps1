foreach ($c in ((Get-Command "Get*VirtualDirectory" -CommandType Function).Name)) {& $c -server $env:COMPUTERNAME | Format-List Name,InternalUrl,ExternalUrl}
