# A fun way to find every cmdlet that gets Exchange virtual directories and then pipe that list to run it against the current server.
foreach ($c in ((Get-Command "Get*VirtualDirectory" -CommandType Function).Name)) {& $c -server $env:COMPUTERNAME | Format-List Name,InternalUrl,ExternalUrl}
