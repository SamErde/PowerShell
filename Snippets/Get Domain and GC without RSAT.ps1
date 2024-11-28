Add-Type -AssemblyName 'System.DirectoryServices'
Add-Type -AssemblyName 'System.Net.NetworkInformation'

# Works when offline, returns the DNS domain name, not the NetBIOS domain name.
( [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties() ).DomainName

# Requires domain connectivity, returns the DNS domain name, not the NetBIOS domain name.
[System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name

# Find a global catalog server
[System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Forest.FindGlobalCatalog().Name

# Find a domain controller
[System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().FindDomainController().Name
