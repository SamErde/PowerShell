# Load the .NET assembly to make it available to the whole script or session
[System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices")

# Since that may be deprecated, use:
Add-Type -AssemblyName 'System.DirectoryServices'
Add-Type -AssemblyName 'System.Net.NetworkInformation'

# Find the full name of the assembly by running:
# Add-Type -AssemblyName $TypeName -PassThru | Select-Object -ExpandProperty Assembly | Select-Object -ExpandProperty FullName -Unique



# Works when offline, returns the DNS domain name, not the NetBIOS domain name.
( [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties() ).DomainName

# Requires domain connectivity, returns the DNS domain name, not the NetBIOS domain name.
[System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name