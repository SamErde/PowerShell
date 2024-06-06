<#
    .SYNOPSIS
    An experimental way to get the list of URLs used by Microsoft 365 services.

    .DESCRIPTION


    .EXAMPLE
        Get-InstanceNames

        Pull a list of all Microsoft cloud instance names. They include the general worldwide instance, government, DoD, and foreign instances.
        
    .EXAMPLE
        Get-ServiceAreas

        Pulls a list of the services area names found within a given instance.

            Example: pull a list of service areas for the USGovGCCHigh instance.
            Get-ServiceAreas -Instance USGovGCCHigh

    .EXAMPLE
        Get-ServiceURLs

        Pull a list of service URLs for a specific instance service area.

            Example: get the Exchange service URLs for USGovGCCHigh.
            Get-ServiceURLs -Instance USGovGCCHigh -ServiceArea Exchange

    .NOTES
    Reference Documentation:
        
        Office 365 IP Addresses and URL Web Service
        https://docs.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-ip-web-service?view=o365-worldwide

        Microsoft Graph: National Cloud Deployments
        https://docs.microsoft.com/en-us/graph/deployments
#>

# $Guid = New-Guid
[Guid]$global:Guid = "f31523fa-cb44-44e6-9a13-037a0643e282"

function Get-InstanceNames {
    # Get a list of available cloud instance names (gov, foreign, worldwide, etc) using a GUID for the request.
    $UriInstanceNames = "https://endpoints.office.com/version?clientrequestid=$Guid"
    $global:InstanceNames = ( ( (Invoke-WebRequest -Uri $UriInstanceNames).Content ) | ConvertFrom-Json ).instance
} # End function Get-InstanceNames

Get-InstanceNames

function Get-ServiceAreas {
    # Get all service area names for a given instance.
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            if (!($global:InstanceNames)) {
                Get-InstanceNames
            }
            else {
                Return $global:InstanceNames
            }
        })]
        [string]
        $Instance
    )

    $Uri = "https://endpoints.office.com/endpoints/$Instance"+"?clientrequestid=$Guid"
    $global:ServiceAreas = ( ( ((Invoke-WebRequest -Uri $Uri).Content) | ConvertFrom-Json ) | Select-Object serviceArea -Unique).servicearea
    Return $global:ServiceAreas
} # End function Get-ServiceAreas

function Get-ServiceUrls {
    # Get all service URLs for a selected instance and service area.
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ArgumentCompleter({
            param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
            if (!($global:InstanceNames)) {
                Get-InstanceNames
            }
            else {
                Return $global:InstanceNames
            }
        })]
        [string]
        $Instance,
        [ArgumentCompleter(
            {
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                if (!($global:InstanceNames)) {
                    Get-InstanceTypes
                }
                elseif (!($ServiceAreas)) {
                    if (!($Instance)) {
                        $Instance = "Worldwide"
                    }
                    Get-ServiceAreas -InstanceName $Instance
                }
                else {
                    Return $global:ServiceAreas
                }
            }
        )]
        [string]
        $ServiceArea
    )

    $Uri = "https://endpoints.office.com/endpoints/$Instance"+"?clientrequestid=$Guid"+'&'+"serviceArea=$ServiceArea"
    $global:ServiceUrls = ( ( ((Invoke-WebRequest -Uri $Uri).Content) | ConvertFrom-Json ) | Select-Object urls -Unique).urls
    Return $global:ServiceUrls
}


#region Appendix

<# SCRATCH PAD
    # Fun, but probably not necessary:
    [Guid]$global:Guid = "f31523fa-cb44-44e6-9a13-037a0643e282"
    $UriInstanceNames = "https://endpoints.office.com/version?clientrequestid=$Guid"
    $global:InstanceNames = ( ( (Invoke-WebRequest -Uri $UriInstanceNames).Content ) | ConvertFrom-Json ).instance

    foreach ($item in $InstanceNames) {
        $VariableName = '$Endpoints'+"$item"
        $Expression = "$Variablename = " + '"' + "https://endpoints.office.com/endpoints/"+"$item"+"?clientrequestid=$($Guid)" + '"'
        Invoke-Expression $Expression
        Write-Output `n"A new URI variable has been created for $item : " $Expression
    } 

#>

# SAMPLE JSON DATA
<# SAMPLE INSTANCE OUTPUT
    [
    {
        "instance": "Worldwide",
        "latest": "2021102900"
    },
    {
        "instance": "USGovDoD",
        "latest": "2021102900"
    },
    {
        "instance": "USGovGCCHigh",
        "latest": "2021102900"
    },
    {
        "instance": "China",
        "latest": "2021092800"
    },
    {
        "instance": "Germany",
        "latest": "2021102900"
    }
    ]
#>

<# SAMPLE GCCHIGH OUTPUT
    [
    {
        "id": 1,
        "serviceArea": "Exchange",
        "serviceAreaDisplayName": "Exchange Online",
        "urls": [
        "outlook.office365.us"
        ],
        "ips": [
        "20.35.208.0/20",
        "20.35.240.0/21",
        "40.66.16.0/21",
        "131.253.83.0/26",
        "131.253.84.64/26",
        "131.253.84.192/26",
        "131.253.86.0/24",
        "131.253.87.144/28",
        "131.253.87.208/28",
        "131.253.87.240/28",
        "131.253.88.0/28",
        "131.253.88.32/28",
        "131.253.88.48/28",
        "131.253.88.96/28",
        "131.253.88.128/28",
        "131.253.88.144/28",
        "131.253.88.160/28",
        "131.253.88.192/28",
        "131.253.88.240/28",
        "2001:489a:2200:28::/62",
        "2001:489a:2200:3c::/62",
        "2001:489a:2200:44::/62",
        "2001:489a:2200:58::/61",
        "2001:489a:2200:60::/62",
        "2001:489a:2200:79::/64",
        "2001:489a:2200:7d::/64",
        "2001:489a:2200:7f::/64",
        "2001:489a:2200:80::/64",
        "2001:489a:2200:82::/63",
        "2001:489a:2200:86::/64",
        "2001:489a:2200:88::/63",
        "2001:489a:2200:8a::/64",
        "2001:489a:2200:8c::/64",
        "2001:489a:2200:8f::/64",
        "2001:489a:2200:100::/56",
        "2001:489a:2200:400::/56",
        "2001:489a:2200:600::/56"
        ],
        "tcpPorts": "80,443",
        "expressRoute": true,
        "category": "Optimize",
        "required": true
    }
    ]
#>

#endregion Appendix
