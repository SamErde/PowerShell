# When you have a security principal
((Get-WinEvent -FilterHashtable @{LogName = 'System'; ID=1501} -MaxEvents 1).UserId).Translate([System.Security.Principal.NTAccount]).Value

# When you have a SID as a string
[System.Security.Principal.SecurityIdentifier]::new($sid).Translate([System.Security.Principal.NTAccount]).value
