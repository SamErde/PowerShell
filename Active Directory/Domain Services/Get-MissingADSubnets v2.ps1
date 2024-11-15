function Get-MissingADSubnets {
    <#
    .SYNOPSIS
        Generate a list of missing AD subnets based on the netlogon log info from domain controllers.

    .DESCRIPTION
        This script collects netlogon log information from domain controllers and exports a list of subnets that are
        missing from Active Directory Sites and Services. It can collect data from all domain controllers in a specific
        AD domain, from a list of specific domain controllers, or from previously collected netlogon logs.

        First, the script collects remotely the netlogon log file from:
                 specified domain controllers
            <or> domain controllers from a specific domain
            <or> domain controllers from the entire forest

        When the data are collected, the script extracts the NO_CLIENT_SITE entries and computes missing subnets from them.

        In case the log data is old and already resolved, the script checks see if the missing subnets were already
        created in AD sites and services.

    .NOTES
        Original Author: Alexandre Augagneur
        Refactoring Author: Sam Erde (www.day3bits.com)
        Version: 2.0.0-prerelease

        Update - 2024/11/15 : Refactor with updated standards, formatting, and validation.
            Convert functions to advanced functions with new/updated comment-based help.
            Add type hints to function parameters.
            Declare parameters with explicit types (testing needed).
            Replace 'exit' statements with 'return' or 'break' statements.
            Add end tags to if/foreach/switch statements and to functions.
            Fix region/endregion tags.
            Replace 'Get-WmiObject' with 'Get-CimInstance' in Get-NetlogonLogUNC function.
            Use approved verbs for function names.
                Rename 'Compute-IPv4' to 'New-IPv4'
                Rename 'Compute-IPv4NetworkAddress' to 'New-IPv4NetworkAddress'
                Rename 'Retrieve-DomainController' to 'Get-DomainControllerOSVersion'
                Rename 'Get-NetlogonPath' to 'Get-NetlogonLogUNC'

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
        Collect data from all domain controllers in a specific AD domain.

        If this parameter is specified and the parameters 'Server' and 'ExistingData' are not specified, the script will
        collect data from all domain controllers in the forest.

    .PARAMETER Server
        List of domain controllers to collect data from.

    .PARAMETER ExistingData
        Path of previously collected netlogon logs to inspect.

    .PARAMETER Path
        Path to save the exported files in.

    .PARAMETER CollectOnly
        Collect only netlogon entries (parameter not available with the ExistingData parameter.

    .PARAMETER IPv4Mask
        The netmask in decimal form (CIDR notation) to compute the missing subnets (default 24).

    .PARAMETER nbLines
        The number of lines to get from a netlogon.log file (default 500).
    .LINK
        https://github.com/SamErde
    .LINK
        https://www.day3bits.com
    .LINK
        https://linktree.com/SamErde
    #>
    #Requires -version 3
    [CmdletBinding()]

    param (
        [Parameter(ParameterSetName = 'Domain')]
        [String]
        $Domain,

        [Parameter(ParameterSetName = 'Server', Mandatory = $true)]
        [String[]]
        $Server,

        [Parameter(ParameterSetName = 'Data', Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [String]
        $ExistingData,

        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [String]
        $Path,

        [parameter(ParameterSetName = 'Domain')]
        [parameter(ParameterSetName = 'Server')]
        [Switch]
        $CollectOnly,

        [Parameter()]
        [ValidateRange(1, 32)]
        [int] $IPv4Mask = 24,

        [Parameter()]
        [int] $nbLines = 500
    )

    #region Functions

    function New-IPv4 {
        <#
            .SYNOPSIS
            Create the IPv4 Object
            .DESCRIPTION
            Compute the needed IPv4 object.
        #>
        [CmdletBinding()]
        param (
            # The object...
            [Parameter()]
            [Object]
            $Obj,

            # The IPv4 address to compute the network address
            [Parameter()]
            # [System.Net.IPAddress] # test to ensure this type works as expected when previously untyped
            $ObjInputAddress,

            # The IPv4 netmask in decimal format
            [Parameter()]
            #[int] # test to ensure this type works as expected when previously untyped
            $IPv4Mask
        )

        $Obj | Add-Member -Type NoteProperty -Name Type -Value 'IPv4'

        # Compute IP length
        [int] $IntIPLength = 32 - $IPv4Mask

        # Returns the number of block-size
        [int] $BlockBytes = [Math]::Floor($IntIPLength / 8)

        $NumberOfIPs = ([System.Math]::Pow(2, $IntIPLength)) - 1

        $IpStart = New-IPv4NetworkAddress $ObjInputAddress $BlockBytes $IPv4Mask
        $Obj | Add-Member -type NoteProperty -Name Subnet -Value "$($IpStart)/$($IPv4Mask)"
        $Obj | Add-Member -type NoteProperty -Name IpStart -Value $IpStart

        $ArrBytesIpStart = $IpStart.GetAddressBytes()
        [array]::Reverse($ArrBytesIpStart)
        $RangeStart = [system.bitconverter]::ToUInt32($ArrBytesIpStart, 0)

        $IpEnd = $RangeStart + $NumberOfIPs

        if (($IpEnd.Gettype()).Name -ine 'double') {
            $IpEnd = [Convert]::ToDouble($IpEnd)
        }

        $IpEnd = [System.Net.IPAddress] $IpEnd
        $Obj | Add-Member -type NoteProperty -Name IpEnd -Value $IpEnd

        $Obj | Add-Member -type NoteProperty -Name RangeStart -Value $RangeStart

        $ArrBytesIpEnd = $IpEnd.GetAddressBytes()
        [array]::Reverse($ArrBytesIpEnd)
        $Obj | Add-Member -type NoteProperty -Name RangeEnd -Value ([system.bitconverter]::ToUInt32($ArrBytesIpEnd, 0))

        # return $Obj
        $Obj
    } # end function New-IPv4

    function New-IPv4NetworkAddress {
        <#
        .SYNOPSIS
        Compute the new IPv4 address based on the block-size
        .DESCRIPTION
        Compute the new IPv4 address based on the block-size
        #>
        [CmdletBinding()]
        param (
            # The IPv4 address to compute the network address
            #[System.Net.IPAddress] # test to ensure this type works as expected when previously untyped
            $Address,

            # The address block-size
            #[int] # test to ensure this type works as expected when previously untyped
            $nbBytes,

            # The IPv4 netmask in decimal format
            #[int] # test to ensure this type works as expected when previously untyped
            $IPv4Mask
        )

        $ArrBytesAddress = $Address.GetAddressBytes()
        [array]::Reverse($ArrBytesAddress)

        # Sets a Block-Size to 0 if it is a part of the network length
        for ( $i = 0; $i -lt $nbBytes; $i++ ) {
            $ArrBytesAddress[$i] = 0
        }

        # Returns the remaining bits of the prefix
        $Remaining = $obj.Prefix % 8

        if ( $Remaining -gt 0 ) {
            $Mask = ([Math]::Pow(2, $Remaining) - 1) * ([Math]::Pow(2, 8 - $Remaining))
            $BlockBytesValue = $ArrBytesAddress[$i] -band $Mask
            $ArrBytesAddress[$i] = $BlockBytesValue
        }

        [array]::Reverse($ArrBytesAddress)
        $NetworkAddress = [System.Net.IPAddress] $ArrBytesAddress

        #return $NetworkAddress
        $NetworkAddress
    } # end function New-IPv4NetworkAddress

    function Get-DomainControllerOSVersion {
        <#
        .SYNOPSIS
        Get the OS version of a domain controller.
        .DESCRIPTION
        Connect to the specified domain controller and retrieve the OS version.
        #>
        [CmdletBinding()]
        # [OutputType()] - does this return a string or a version type?
        param (
            # Hostname of the DC to get the OS version from
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Hostname
        )

        $context = New-Object System.directoryServices.ActiveDirectory.DirectoryContext('DirectoryServer', $hostname)

        # return the results
        try {
            $OSVersion = ([System.directoryServices.ActiveDirectory.DomainController]::GetDomainController($context)).OSVersion
            #return
            $OSVersion
        } catch {
            Write-Host 'Unable to contact the domain controller.' -ForegroundColor Red
            #return
            $null
        }
    } # end function Get-DomainControllerOSVersion

    function Get-NetlogonLogUNC {
        <#
        .DESCRIPTION
        Get a UNC for the netlogon.log on a remote domain controller.
        #>
        [CmdletBinding()]
        [OutputType([string])]
        param (
            # Hostname of the DC to get the netlogon log file path
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Hostname
        )

        # Add a Test-NetConnection to check availability and SMB access to UNC.

        # Return the remote netlogon path
        try {
            $CimObj = Get-CimInstance -ClassName Win32_OperatingSystem -Property SystemDirectory
            $Path = '\\' + $hostname + '\' + ((Split-Path $CimObj.SystemDirectory -Parent) -replace ':', '$') + '\debug\netlogon.log'
            #return
            $Path
        } catch {
            Write-Error -Message "Unable to retrieve netlogon.log path for $hostname."
            # return
            $null
        }
    } # end function Get-NetlogonLogUNC

    #endregion functions


    #region Main

    # Connect to Active Directory
    $objRootDSE = [System.DirectoryServices.DirectoryEntry] 'LDAP://rootDSE'
    $DCs = @()
    $LogEntries = @()

    # Construct the list of domain controllers to be treated by the script
    if ( $PSCmdlet.ParameterSetName -eq 'Server' ) {
        $DCs = $Server
    } elseif ( $PSCmdlet.ParameterSetName -eq 'Data' ) {
        $CollectedFiles = Get-ChildItem -Path $ExistingData -Filter '*-Netlogon.log'
        Write-Host "`nNumber of files found: " -NoNewline

        if ( $CollectedFiles.Count -gt 0 ) {
            Write-Host $CollectedFiles.Count -ForegroundColor Magenta
        } else {
            Write-Host 0 -ForegroundColor Red
            return
            #Exit
        }

        $i = 1
        foreach ( $File in $CollectedFiles ) {
            $Content = Get-Content -Path $File.FullName -Tail $nbLines

            Write-Host "($i/$($CollectedFiles.Count)) Loading entries from: " -NoNewline
            Write-Host "$($File.FullName)" -ForegroundColor Green

            # Search the NO_CLIENT_SITE entries in the netlogon log file and capture the IP address of each entry (only IPv4)
            foreach ( $Line in $Content ) {
                if ( $Line -match 'NO_CLIENT_SITE:\s*(.*?)\s*(\d*\.\d*\.\d*\.\d*)' ) {
                    $Obj = New-Object -TypeName PsObject
                    $Obj | Add-Member -Type NoteProperty -Name Computer -Value ($matches[1])
                    $Obj | Add-Member -Type NoteProperty -Name IpAddress -Value ($matches[2])
                    $LogEntries += $Obj
                }
            }
            $i++
        } # end foreach $File
    } else {
        if ( [string]::IsNullOrEmpty($Domain) ) {
            $ArrReadHost = @('yes', 'y', 'no', 'n')
            $Confirm = $null

            # Request confirmation to retrieve the netlogon file from all DCs on the forest
            while ( $ArrReadHost -notcontains $Confirm ) {
                Write-Warning "The script is going to retrieve the netlogon log file of all domain controllers in the forest.`nDo you want to proceed? (Y/N)"
                $Confirm = Read-Host
            }

            if ( $Confirm -like 'n*' ) {
                Write-Host 'Operation canceled.' -ForegroundColor Yellow
                return
                #Exit
            } else {
                # Connect to the current forest
                $ADSIForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()

                # Retrieve the list of all DCs within the forest
                foreach ( $ADSIDomain in $ADSIForest.Domains ) {
                    $DCs += $ADSIDomain.DomainControllers
                }
            } # end if
        } else {
            # Connect to the specified domain and retrieve the list of all DCs within this domain
            $DomainContext = New-Object System.directoryServices.ActiveDirectory.DirectoryContext('Domain', $Domain)
            $ADSIDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
            $DCs += $ADSIDomain.DomainControllers
        } # end if [string]::IsNullOrEmpty($Domain)
    } # end if PSCmdlet.ParameterSetName

    # Treat list of domain controllers if existing data are not used
    if ( $PSCmdlet.ParameterSetName -ne 'Data' ) {
        # Treatment of each domain controller
        Write-Host "`nNumber of Domain Controllers to treat: " -NoNewline

        if ( $DCs.Count -gt 0 ) {

            Write-Host $DCs.Count -ForegroundColor Magenta

            foreach ( $DC in $DCs ) {
                Write-Host "$($DC): " -NoNewline

                $DCVersion = Get-DomainControllerOSVersion $DC

                # Windows 2000 Server not supported by the script
                if ( -not([string]::IsNullOrEmpty($DCVersion)) ) {
                    if ( $DCVersion -like '*2000*' ) {
                        Write-Host "$($DCVersion) not supported by the script." -ForegroundColor Red
                    } else {
                        Write-Host 'Connection established.' -ForegroundColor Green
                        Write-Host "$($DC): " -NoNewline

                        # Retrieve the netlogon file path for the specified DC
                        $NetLogonPath = Get-NetlogonLogUNC $DC

                        if ( -not([string]::IsNullOrEmpty($NetLogonPath)) ) {
                            if ( Test-Path $NetLogonPath -ErrorAction SilentlyContinue ) {
                                Write-Host 'Retrieving NO_CLIENT_SITE entries from logs...' -ForegroundColor Green

                                $Content = Get-Content -Path $NetLogonPath -Tail $nbLines

                                # Saving the netlogon content of each DC
                                $Content | Out-File "$($Path)\$($DC.ToString().split('.')[0])-Netlogon.log" -Force

                                # Search the NO_CLIENT_SITE entries in the netlogon log file
                                # Capture the IP address of each entry (only IPv4)
                                Foreach ( $Line in $Content ) {
                                    if ( $Line -match 'NO_CLIENT_SITE:\s*(.*?)\s*(\d*\.\d*\.\d*\.\d*)' ) {
                                        $Obj = New-Object -TypeName PsObject
                                        $Obj | Add-Member -type NoteProperty -Name Computer -Value ($matches[1])
                                        $Obj | Add-Member -type NoteProperty -Name IpAddress -Value ($matches[2])
                                        $LogEntries += $Obj
                                    }
                                }
                            } else {
                                Write-Host "Unable to access to $($NetLogonPath): $($_.Exception.Message)" -ForegroundColor Red
                            } # end if Test-Path
                        } # end if -not([string]::IsNullOrEmpty($NetLogonPath))
                    } # end if $DCVersion -like '*2000*'
                } # end if -not([string]::IsNullOrEmpty($DCVersion))
            } # end foreach $DC
        } else {
            Write-Host 0 -ForegroundColor Red
            return
            #Exit
        } # end if $DCs.Count -gt 0
    } # end if PSCmdlet.ParameterSetName

    # If data collected the script start to compute the list of missing subnets
    if ( ($LogEntries.Count -gt 0) -and ($CollectOnly -eq $false) ) {
        # Remove duplicated IP addresses
        $LogEntries = $LogEntries | Select-Object * -Unique

        $ArrIPs = @()

        # Each IP is converted to a subnet based on the IPv4Mask argument (24 bits by default)
        foreach ( $Entry in $LogEntries ) {
            $ObjIP = [System.Net.IPAddress] $Entry.IpAddress

            $SubnetObj = New-Object -TypeName PsObject

            if ( $ObjIP.AddressFamily -match 'InterNetwork' ) {
                $SubnetObj = New-IPv4 $SubnetObj $ObjIP $IPv4Mask
                $SubnetObj | Add-Member -MemberType NoteProperty -Name Computer -Value $Entry.Computer
                $ArrIPs += $SubnetObj
            } # end if $ObjIP.AddressFamily -match 'InterNetwork'
        } # end foreach $Entry

        # Remove duplicated subnets
        $ArrIPs = $ArrIPs | Sort-Object RangeStart | Select-Object * -Unique

        # Create only one entry per subnet with the list of computers associated to this subnet
        $Subnets = $ArrIPs | Select-Object Type, Subnet, IpStart, IpEnd, RangeStart, RangeEnd | Sort-Object Subnet -Unique
        $TempArray = @()

        foreach ( $Subnet in $Subnets ) {
            $ArrComputers = @()
            $ArrIPs | Where-Object { $_.Subnet -eq $Subnet.Subnet } | ForEach-Object { $ArrComputers += $_.Computer }
            $Subnet | Add-Member -MemberType NoteProperty -Name Computers -Value ($ArrComputers -join ' ')
            $TempArray += $Subnet
        } # end foreach $Subnet

        $ArrIPs = $TempArray | Sort-Object RangeStart

        # Retrieve AD subnets to check if missing subnets found in the netlogon files have not been added during the interval
        Write-Host "`nRetrieving AD subnets: " -NoNewline

        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.SearchRoot = New-Object System.DirectoryServices.DirectoryEntry('LDAP://cn=subnets,cn=sites,' + $objRootDSE.ConfigurationNamingContext)
        $Searcher.PageSize = 10000
        $Searcher.SearchScope = 'Subtree'
        $Searcher.Filter = '(objectClass=subnet)'

        $Properties = @('cn', 'location', 'siteobject')
        $Searcher.PropertiesToLoad.AddRange(@($Properties))
        $Subnets = $Searcher.FindAll()

        $selectedProperties = $Properties | ForEach-Object { @{name = "$_"; expression = $ExecutionContext.InvokeCommand.NewScriptBlock("`$_['$_']") } }
        [Regex] $RegexCN = 'CN=(.*?),.*'
        $SubnetsArray = @()

        foreach ( $Subnet in $Subnets ) {
            # Construct the subnet object
            $SubnetObj = New-Object -TypeName PsObject
            $SubnetObj | Add-Member -type NoteProperty -Name Name -Value ([string] $Subnet.Properties['cn'])
            $SubnetObj | Add-Member -type NoteProperty -Name Location -Value ([string] $Subnet.Properties['location'])
            $SubnetObj | Add-Member -type NoteProperty -Name Site -Value ([string] $RegexCN.Match( $Subnet.Properties['siteobject']).Groups[1].Value)

            $InputAddress = (($SubnetObj.Name).Split('/'))[0]
            $ADSubnetPrefix = (($SubnetObj.Name).Split('/'))[1]

            # Construct System.Net.IPAddress
            $ObjInputAddress = [System.Net.IPAddress] $InputAddress

            # Check if IP is a IPv4 (IPv6 not collected)
            if ( $ObjInputAddress.AddressFamily -eq 'InterNetwork' ) {
                $SubnetObj = New-IPv4 $SubnetObj $ObjInputAddress $ADSubnetPrefix
                $SubnetsArray += $SubnetObj
            } # end if $ObjInputAddress.AddressFamily -eq 'InterNetwork'
        } # end foreach $Subnet

        $SubnetsArray | Export-Csv "$($Path)\ADSubnets-Export.csv" -Delimiter ';' -NoTypeInformation -Force

        if ( Test-Path "$($Path)\ADSubnets-Export.csv" ) {
            Write-Host "$($Path)\ADSubnets-Export.csv" -ForegroundColor Green
        } else {
            Write-Host 'Error while exporting result to file.' -ForegroundColor Yellow
        } # end if Test-Path

        $Subnets = $SubnetsArray | Sort-Object -Property RangeStart

        # Check if subnets are not already created
        foreach ($Item in $ArrIPs) {
            $SubnetIsExisting = $Subnets | Where-Object { ($Item.RangeStart -ge $_.RangeStart) -and ($Item.RangeEnd -le $_.RangeEnd) }

            if ( ($SubnetIsExisting) -and ($ArrIPs.Count -gt 1) ) {
                [array]::Clear($ArrIPs, ([array]::IndexOf($ArrIPs, $Item)), 1)
            } # end if
        } # end foreach

        # Export Missing subnets
        if ( $ArrIPs ) {
            $ArrIPs | Where-Object Type -NE $null | Export-Csv "$($Path)\ADSubnets-MissingSubnets.csv" -Delimiter ';' -NoTypeInformation -Force

            if ( Test-Path "$($Path)\ADSubnets-MissingSubnets.csv" ) {
                Write-Host "`nList of missing subnets: " -NoNewline
                Write-Host "$($Path)\ADSubnets-MissingSubnets.csv" -ForegroundColor Green
            } else {
                Write-Host "`nError while exporting missing subnets to file." -ForegroundColor Red
            } # end if Test-Path
        } else {
            Write-Host "`nNo Missing subnet found. Try with a greater netmask." -ForegroundColor Yellow
        } # end if $ArrIPs
    } # end if ($LogEntries.Count -gt 0) -and ($CollectOnly -eq $false)

    #endregion Main

} # end function Collect-MissingADSubnets
