# I just found this old script that was horribly written and am slowly fixing it up. 😅

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

[guid]$Guid = 'f31523fa-cb44-44e6-9a13-037a0643e282'

function Get-InstanceNames {
    # Get a list of available cloud instance names (gov, foreign, worldwide, etc) using a GUID for the request.
    $UriInstanceNames = "https://endpoints.office.com/version?clientrequestid=$Guid"
    $InstanceNames = ( ( (Invoke-WebRequest -Uri $UriInstanceNames).Content ) | ConvertFrom-Json ).instance
    return $InstanceNames
} # End function Get-InstanceNames

function Get-ServiceAreas {
    # Get all service area names for a given instance.
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ArgumentCompleter({
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                if (!($InstanceNames)) {
                    Get-InstanceNames
                } else {
                    return $InstanceNames
                }
            })]
        [string]
        $Instance
    )

    $Uri = "https://endpoints.office.com/endpoints/$Instance" + "?ClientRequestId=$Guid"
    $ServiceAreas = ( ( ((Invoke-WebRequest -Uri $Uri).Content) | ConvertFrom-Json ) | Select-Object serviceArea -Unique).ServiceArea
    return $ServiceAreas
} # End function Get-ServiceAreas

function Get-ServiceUrls {
    # Get all service URLs for a selected instance and service area.
    [CmdletBinding()]
    param (
        [Parameter()]
        [ArgumentCompleter({
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                if (!($InstanceNames)) {
                    Get-InstanceNames
                } else {
                    return $InstanceNames
                }
            })]
        [string]
        $Instance = 'Worldwide',
        [ArgumentCompleter(
            {
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                if (!($InstanceNames)) {
                    Get-InstanceTypes
                } elseif (!($ServiceAreas)) {
                    if (!($Instance)) {
                        $Instance = 'Worldwide'
                    }
                    Get-ServiceAreas -InstanceName $Instance
                } else {
                    return $ServiceAreas
                }
            }
        )]
        [string]
        $ServiceArea
    )

    $Uri = "https://endpoints.office.com/endpoints/$Instance" + "?ClientRequestId=$Guid" + '&' + "serviceArea=$ServiceArea"
    $ServiceUrls = ( ( ((Invoke-WebRequest -Uri $Uri).Content) | ConvertFrom-Json ) | Select-Object urls -Unique).urls
    return $ServiceUrls
}
