#Requires -version 3

<#
.SYNOPSIS
	The script is generating an export of missing AD subnets based on the netlogon log info of 
	specified domain controllers.

	In first, the script is collecting remotely the netlogon log file from:
	specified domain controllers
	<or> domain controllers from a specific domain
	<or> domain controllers from the entire forest
	
	When data are collected, the script extract the NO_CLIENT_SITE entries and compute
	the missing subnets from them.
	
	The script check at the end if the missing subnets were not already created on AD by
	extracting the list of AD subnets.
	
.NOTES
	Author		: Alexandre Augagneur (www.alexwinner.com)
	File Name	: Collect-MissingADSubnets.ps1
	
	Update - 04/22/2014 : New field 'Computers' added in the export (list of computers concerned by each missing subnet).
	Update - 06/16/2013 : Fixed issues related to existing subnets.
	
.EXAMPLE
	.\Collect-MissingADSubnets.ps1 -Path C:\Temp -Domain "corpnet.net"
	
.EXAMPLE
	.\Collect-MissingADSubnets.ps1 -Path C:\Temp -Server "dc01.corpnet.net","dc02.corpnet.net"

.EXAMPLE
	.\Collect-MissingADSubnets.ps1 -Path C:\Temp -IPv4Mask 16 -nbLines 250

.EXAMPLE
	.\Collect-MissingADSubnets.ps1 -Path C:\Temp -IPv4Mask 16 -nbLines 250 -CollectOnly
	
.EXAMPLE
	.\Collect-MissingADSubnets.ps1 -Path C:\Temp -ExistingData c:\CollectedData


	
.PARAMETER Domain
	Collect data from domain controllers of a specific AD domain. If this parameter, the parameters 'Server'
	and 'ExistingData' are not specified, the script is collecting data of all domain controllers of the forest.

.PARAMETER Server
	List of domain controllers to collect data
	
.PARAMETER ExistingData
	Path of previous collected netlogon logs to treat
	
.PARAMETER Path
	Path for the exported files
	
.PARAMETER CollectOnly
	Collect only netlogon entries (parameter not available with parameter ExistingData
	
.PARAMETER IPv4Mask
	The netmask in decimal to compute the missing subnets (default 24)
	
.PARAMETER nbLines
	The number of lines to grab from a netlogon file (default 500)
#>

param
(	
	[Parameter(ParameterSetName="Domain")]
	[String] $Domain,
	
	[Parameter(ParameterSetName="Server",Mandatory=$true)]
	[String[]] $Server,
	
	[Parameter(ParameterSetName="Data",Mandatory=$true)]
	[ValidateScript({Test-Path $_ -PathType Container})]
	[String] $ExistingData,
	
	[Parameter(Mandatory=$true)]
	[ValidateScript({Test-Path $_ -PathType Container})]
	[String] $Path,
	
	[parameter(ParameterSetName="Domain")]
    [parameter(ParameterSetName="Server")]
	[Switch]
	$CollectOnly,
	
	[Parameter()]
	[ValidateRange(1,32)]
	[int] $IPv4Mask = 24,
	
	[Parameter()]
	[int] $nbLines = 500
)

#Region Functions

####################################################
# Functions
####################################################

#---------------------------------------------------
# Create the IPv4 object
#---------------------------------------------------
function Compute-IPv4 ( $Obj, $ObjInputAddress, $IPv4Mask )
{
	$Obj | Add-Member -type NoteProperty -name Type -value "IPv4"
	
	# Compute IP length
    [int] $IntIPLength = 32 - $IPv4Mask
		
	# Returns the number of block-size
	[int] $BlockBytes = [Math]::Floor($IntIPLength / 8)
	
	$NumberOfIPs = ([System.Math]::Pow(2, $IntIPLength)) -1

	$IpStart = Compute-IPv4NetworkAddress $ObjInputAddress $BlockBytes $IPv4Mask
	$Obj | Add-Member -type NoteProperty -name Subnet -value "$($IpStart)/$($IPv4Mask)"
	$Obj | Add-Member -type NoteProperty -name IpStart -value $IpStart

	$ArrBytesIpStart = $IpStart.GetAddressBytes()
	[array]::Reverse($ArrBytesIpStart)
	$RangeStart = [system.bitconverter]::ToUInt32($ArrBytesIpStart,0)

	$IpEnd = $RangeStart + $NumberOfIPs

	If (($IpEnd.Gettype()).Name -ine "double")
	{
		$IpEnd = [Convert]::ToDouble($IpEnd)
	}

	$IpEnd = [System.Net.IPAddress] $IpEnd
	$Obj | Add-Member -type NoteProperty -name IpEnd -value $IpEnd

	$Obj | Add-Member -type NoteProperty -name RangeStart -value $RangeStart
	
	$ArrBytesIpEnd = $IpEnd.GetAddressBytes()
	[array]::Reverse($ArrBytesIpEnd)
	$Obj | Add-Member -type NoteProperty -name RangeEnd -value ([system.bitconverter]::ToUInt32($ArrBytesIpEnd,0))
	
	Return $Obj
}

#---------------------------------------------------
# Compute the network address
#---------------------------------------------------
function Compute-IPv4NetworkAddress ( $Address, $nbBytes, $IPv4Mask )
{
	$ArrBytesAddress = $Address.GetAddressBytes()
	[array]::Reverse($ArrBytesAddress)

	# Sets a Block-Size to 0 if it is a part of the network length
	for ( $i=0; $i -lt $nbBytes; $i++ )
	{
		$ArrBytesAddress[$i] = 0
	}
	
	# Returns the remaining bits of the prefix
	$Remaining =  $obj.Prefix % 8
	
	if ( $Remaining -gt 0 )
	{
		$Mask = ([Math]::Pow(2,$Remaining)-1)*([Math]::Pow(2,8-$Remaining))
		$BlockBytesValue = $ArrBytesAddress[$i] -band $Mask
		$ArrBytesAddress[$i] = $BlockBytesValue
	}

	[array]::Reverse($ArrBytesAddress)
	$NetworkAddress = [System.Net.IPAddress] $ArrBytesAddress
	
	Return $NetworkAddress
}

#---------------------------------------------------
# Connect to specified domain controller and retrieve OS Version
#---------------------------------------------------
function Retrieve-DomainController ( $hostname )
{
	$context = new-object System.directoryServices.ActiveDirectory.DirectoryContext('DirectoryServer',$hostname)
	
	try
	{
		$OSVersion = ([System.directoryServices.ActiveDirectory.DomainController]::GetDomainController($context)).OSVersion
		Return $OSVersion
	}
	catch
	{
		Write-Host "Unable to contact the domain controller." -ForegroundColor Red
		Return $null
	}
}

#---------------------------------------------------
# Construct and return the netlogon.log path
#---------------------------------------------------
function Get-NetlogonPath ( $hostname )
{
	try
	{
		$WMIObj = Get-WmiObject Win32_OperatingSystem -Property systemDirectory
		$Path = "\\"+$hostname+"\"+((split-path $WMIObj.SystemDirectory -Parent) -replace ':','$')+"\debug\netlogon.log"
		Return $Path
	}
	catch
	{
		Write-Host "Unable to retrieve netlogon.log path with WMI." -ForegroundColor Red
		Return $null
	}
}

#Endregion

#Region Main

####################################################
# Main
####################################################

# Connect to Active Directory
$objRootDSE = [System.DirectoryServices.DirectoryEntry] "LDAP://rootDSE"
$DCs = @()
$LogEntries = @()

# Construct the list of domain controllers to be treated by the script
if ( $PSCmdlet.ParameterSetName -eq "Server" )
{
	$DCs = $Server
}
elseif ( $PSCmdlet.ParameterSetName -eq "Data" )
{
	$CollectedFiles = Get-ChildItem -Path $ExistingData -Filter "*-Netlogon.log"
	Write-Host "`nNumber of files found: " -NoNewline
	
	if ( $CollectedFiles.Count -gt 0 )
	{
		Write-Host $CollectedFiles.Count -ForegroundColor Magenta
	}
	else
	{
		Write-Host 0 -ForegroundColor Red
		Exit
	}
	
	$i = 1
	
	foreach ( $File in $CollectedFiles )
	{
		$Content = Get-Content -Path $File.FullName -Tail $nbLines
		
		Write-Host "($i/$($CollectedFiles.Count)) Loading entries from: " -NoNewline
		Write-host "$($File.FullName)" -ForegroundColor Green 
		
		# Search the NO_CLIENT_SITE entries in the netlogon log file and capture the IP address of each entry (only IPv4)
		Foreach ( $Line in $Content )
		{
			if ( $Line -match 'NO_CLIENT_SITE:\s*(.*?)\s*(\d*\.\d*\.\d*\.\d*)' )
			{				
				$Obj = New-Object -TypeName PsObject
				$Obj | Add-Member -type NoteProperty -name Computer -value ($matches[1])
				$Obj | Add-Member -type NoteProperty -name IpAddress -value ($matches[2])
				$LogEntries += $Obj
						
			}
		}
		
		$i++
	}
}
else
{
	if ( [string]::IsNullOrEmpty($Domain) )
	{
		$ArrReadHost = @('yes','y','no','n')
		$Confirm = $null
		
		# Request confirmation to retrieve the netlogon file from all DCs on the forest 
		while ( $ArrReadHost -notcontains $Confirm )
		{
			Write-Warning "The script is going to retrieve the netlogon log file of all domain controllers in the forest.`nDo you want to proceed? (Y/N)"
			$Confirm = Read-Host
		}
		
		if ( $Confirm -like "n*" )
		{
			Exit
		}
		else
		{
			# Connect to the current forest
			$ADSIForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
			
			# Retrieve the list of all DCs within the forest
			foreach ( $ADSIDomain in $ADSIForest.Domains )
			{
				$DCs += $ADSIDomain.DomainControllers
			}
		}
	}
	else
	{
		# Connect to the specified domain and retrieve the list of all dcs within this domain
		$DomainContext = new-object System.directoryServices.ActiveDirectory.DirectoryContext("Domain",$Domain)
		$ADSIDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
		$DCs += $ADSIDomain.DomainControllers
	}
}

# Treat list of domain controllers if existing data are not used
if ( $PSCmdlet.ParameterSetName -ne "Data" )
{
	# Treatment of each domain controller
	Write-Host "`nNumber of Domain Controllers to treat: " -NoNewline

	if ( $DCs.Count -gt 0 )
	{

		Write-Host $DCs.Count -ForegroundColor Magenta
			
		foreach ( $DC in $DCs )
		{
			Write-Host "$($DC): " -NoNewline
			
			$DCVersion = Retrieve-DomainController $DC
			
			# Windows 2000 Server not supported by the script
			if ( -not([string]::IsNullOrEmpty($DCVersion)) )
			{
				if ( $DCVersion -like "*2000*" )
				{
					Write-Host "$($DCVersion) not supported by the script." -ForegroundColor Red
				}
				else
				{
					Write-Host "Connection established." -ForegroundColor Green
					Write-Host "$($DC): " -NoNewline
					
					# Retrieve the netlogon file path for the specified DC
					$NetLogonPath = Get-NetlogonPath $DC
					
					if ( -not([string]::IsNullOrEmpty($NetLogonPath)) )
					{
						if ( Test-Path $NetLogonPath -ErrorAction SilentlyContinue )
						{
							Write-Host "Retrieving NO_CLIENT_SITE entries from logs..." -ForegroundColor Green
							
							$Content = Get-Content -Path $NetLogonPath -Tail $nbLines
							
							# Saving the netlogon content of each DC
							$Content | Out-File "$($Path)\$($DC.ToString().split('.')[0])-Netlogon.log" -Force
							
							# Search the NO_CLIENT_SITE entries in the netlogon log file
							# Capture the IP address of each entry (only IPv4)
							Foreach ( $Line in $Content )
							{
								if ( $Line -match 'NO_CLIENT_SITE:\s*(.*?)\s*(\d*\.\d*\.\d*\.\d*)' )
								{				
									$Obj = New-Object -TypeName PsObject
									$Obj | Add-Member -type NoteProperty -name Computer -value ($matches[1])
									$Obj | Add-Member -type NoteProperty -name IpAddress -value ($matches[2])
									$LogEntries += $Obj
								}
							}
						}
						else
						{
							Write-Host "Unable to access to $($NetLogonPath): $($_.Exception.Message)" -ForegroundColor Red
						}
					}
				}
			}
		}
	}
	else
	{
		Write-Host 0 -ForegroundColor Red
		Exit
	}
}

# If data collected the script start to compute the list of missing subnets
if ( ($LogEntries.Count -gt 0) -and ($CollectOnly -eq $false) )
{
	# Remove duplicated IP addresses
	$LogEntries = $LogEntries | Select * -Unique

	$ArrIPs = @()

	# Each IP is converted to a subnet based on the IPv4Mask argument (24 bits by default)
	foreach ( $Entry in $LogEntries )
	{
		$ObjIP = [System.Net.IPAddress] $Entry.IpAddress
		
		$SubnetObj = New-Object -TypeName PsObject
		
		if ( $ObjIP.AddressFamily -match "InterNetwork" )
	    {
			$SubnetObj = Compute-IPv4 $SubnetObj $ObjIP $IPv4Mask
			$SubnetObj | Add-Member -MemberType NoteProperty -Name Computer -Value $Entry.Computer
			$ArrIPs += $SubnetObj
	    }
	}

	# Remove duplicated subnets
	$ArrIPs = $ArrIPs | Sort-Object RangeStart | Select * -Unique
	
	# Create only one entry per subnet with the list of computers associated to this subnet 
	$Subnets = $ArrIPs | Select Type,Subnet,IpStart,IpEnd,RangeStart,RangeEnd | Sort Subnet -Unique
	$TempArray = @()
	
	foreach ( $Subnet in $Subnets )
	{
		$ArrComputers = @()
		$ArrIPs | Where-Object { $_.Subnet -eq $Subnet.Subnet } | %{ $ArrComputers += $_.Computer }
		$Subnet | Add-Member -MemberType NoteProperty -Name Computers -Value ($ArrComputers -join " ")
		$TempArray += $Subnet
	}
	
	$ArrIPs = $TempArray | Sort-Object RangeStart
	
	# Retrieve AD subnets to check if missing subnets found in the netlogon files have not been added during the interval
	Write-Host "`nRetrieving AD subnets: " -NoNewline
	
	$Searcher = New-Object System.DirectoryServices.DirectorySearcher
	$Searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://cn=subnets,cn=sites,"+$objRootDSE.ConfigurationNamingContext)
	$Searcher.PageSize = 10000
	$Searcher.SearchScope = "Subtree"
	$Searcher.Filter = "(objectClass=subnet)"

	$Properties = @("cn","location","siteobject")
	$Searcher.PropertiesToLoad.AddRange(@($Properties))
	$Subnets = $Searcher.FindAll()

	$selectedProperties = $Properties | ForEach-Object {@{name="$_";expression=$ExecutionContext.InvokeCommand.NewScriptBlock("`$_['$_']")}}
	[Regex] $RegexCN = "CN=(.*?),.*"
	$SubnetsArray = @()

	foreach ( $Subnet in $Subnets )
	{
		# Construct the subnet object
		$SubnetObj = New-Object -TypeName PsObject
		$SubnetObj | Add-Member -type NoteProperty -name Name -value ([string] $Subnet.Properties['cn'])
		$SubnetObj | Add-Member -type NoteProperty -name Location -value ([string] $Subnet.Properties['location'])
		$SubnetObj | Add-Member -type NoteProperty -name Site -value ([string] $RegexCN.Match( $Subnet.Properties['siteobject']).Groups[1].Value)
	     
		$InputAddress = (($SubnetObj.Name).Split("/"))[0]
		$ADSubnetPrefix = (($SubnetObj.Name).Split("/"))[1]
		
		# Construct System.Net.IPAddress 
	    $ObjInputAddress = [System.Net.IPAddress] $InputAddress
		
		# Check if IP is a IPv4 (IPv6 not collected)
		if ( $ObjInputAddress.AddressFamily -eq "InterNetwork" )
	    {
			$SubnetObj = Compute-IPv4 $SubnetObj $ObjInputAddress $ADSubnetPrefix
			$SubnetsArray += $SubnetObj
	    }
	}

	$SubnetsArray | Export-Csv "$($Path)\ADSubnets-Export.csv" -Delimiter ";" -NoTypeInformation -Force
	
	if ( Test-Path "$($Path)\ADSubnets-Export.csv" )
	{
		Write-Host "$($Path)\ADSubnets-Export.csv" -ForegroundColor Green
	}
	else
	{
		Write-Host "Error while exporting result to file." -ForegroundColor Yellow
	}
	
	$Subnets = $SubnetsArray | Sort-Object -Property RangeStart

	# Check if subnets are not already created
	foreach ($Item in $ArrIPs)
	{
		$SubnetIsExisting = $Subnets | Where-Object { ($Item.RangeStart -ge $_.RangeStart) -and ($Item.RangeEnd -le $_.RangeEnd) }
		
		if ( ($SubnetIsExisting) -and ($ArrIPs.Count -gt 1) )
		{
			[array]::Clear($ArrIPs,([array]::IndexOf($ArrIPs, $Item)),1)
		}
	}

	# Export Missing subnets
	if ( $ArrIPs )
	{
		$ArrIPs | ? Type -ne $null | Export-Csv "$($Path)\ADSubnets-MissingSubnets.csv" -Delimiter ";" -NoTypeInformation -Force
	
		if ( Test-Path "$($Path)\ADSubnets-MissingSubnets.csv" )
		{
			Write-Host "`nList of missing subnets: " -NoNewline
			Write-Host "$($Path)\ADSubnets-MissingSubnets.csv" -ForegroundColor Green
		}
		else
		{
			Write-Host "`nError while exporting missing subnets to file." -ForegroundColor Red
		}
	}
	else
	{
		Write-Host "`nNo Missing subnet found. Try with a greater netmask." -ForegroundColor Yellow
	}
}

#EndRegion
