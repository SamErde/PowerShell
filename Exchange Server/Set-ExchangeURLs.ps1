<#
    Set our URLs for all Microsoft Exchange Server services.

    Fill in the array of server FQDNs and specify the SMTP namespace, such as mail.domain.com or mailtest.domain.com.
#>

Start-Transcript

$ServerFqdn = @('','','')
$SmtpNameSpace = 'host.domain.tld'
$BaseUri = "https://$SmtpNameSpace"

# Exit if these values have not been set.
if ( !($ServerFqdn) -or ($ServerFqdn.Length -eq 0) -or !($SmtpNameSpace) -or ($SmtpNameSpace.Length -eq 0) ) { Exit }

# Set the Uris for each server specified above
foreach ($item in $ServerFqdn) {

    $ServerShort = $item.Split('.')[0]
    Write-Host -ForegroundColor Cyan "Updating server: $item ($ServerShort) with $BaseUri."

    Write-Host -ForegroundColor Green "$ServerShort : OWA"
    Get-OwaVirtualDirectory -Server $item  | 
    Set-OwaVirtualDirectory -InternalUrl "$BaseUri/owa" -ExternalUrl "$BaseUri/owa" 
    
    Write-Host -ForegroundColor Green "$ServerShort : ECP"
    Get-EcpVirtualDirectory -Server $item  | 
    Set-EcpVirtualDirectory -InternalUrl "$BaseUri/ecp" -ExternalUrl "$BaseUri/ecp" 
    
    Write-Host -ForegroundColor Green "$ServerShort : MAPI"
    Get-MapiVirtualDirectory -Server $item  | 
    Set-MapiVirtualDirectory -InternalUrl "$BaseUri/mapi" -ExternalUrl "$BaseUri/mapi" 
    
    Write-Host -ForegroundColor Green "$ServerShort : OAB"
    Get-OabVirtualDirectory -Server $item  | 
    Set-OabVirtualDirectory -InternalUrl "$BaseUri/OAB" -ExternalUrl "$BaseUri/OAB" 
    
    Write-Host -ForegroundColor Green "$ServerShort : EWS"
    Get-WebServicesVirtualDirectory -Server $item  | 
    Set-WebServicesVirtualDirectory -InternalUrl "$BaseUri/EWS/Exchange.asmx" -ExternalUrl "$BaseUri/EWS/Exchange.asmx" 
    
    Write-Host -ForegroundColor Green "$ServerShort : EAS"
    Get-ActiveSyncVirtualDirectory -Server $item  | 
    Set-ActiveSyncVirtualDirectory -InternalUrl "$BaseUri/Microsoft-Server-ActiveSync" -ExternalUrl "$BaseUri/Microsoft-Server-ActiveSync" 
    
    Write-Host -ForegroundColor Green "$ServerShort : OAW"
    Get-OutlookAnywhere -Server $ServerShort | 
    Set-OutlookAnywhere -ExternalHostname $SmtpNameSpace -InternalHostname $SmtpNameSpace -ExternalClientsRequireSsl:$true -InternalClientsRequireSsl:$true -ExternalClientAuthenticationMethod 'Negotiate' 
    
    Write-Host -ForegroundColor Green "$ServerShort : PS"
    Get-PowerShellVirtualDirectory -Server $item  | 
    Set-PowerShellVirtualDirectory -InternalUrl "http://$item/PowerShell" -ExternalUrl $null 

    Write-Host -ForegroundColor Green "$ServerShort : AutoDiscover"
    (Get-ClientAccessService).Where({$_.Name -eq $ServerShort}) | 
    Set-ClientAccessService -AutodiscoverServiceInternalUri "https://autodiscover.domain.tld/Autodiscover/Autodiscover.xml" 
}

Stop-Transcript

# Check the Uris for each server specified above
foreach ($item in $ServerFqdn) {

    $ServerShort = $ServerFqdn.Split('.')[0]
    Write-Host -ForegroundColor Cyan "Checking server: $item ($ServerShort)."

    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : OWA" ; Get-OwaVirtualDirectory -Server $item | Format-List InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : ECP" ; Get-EcpVirtualDirectory -Server $item | Format-List InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : MAPI" ; Get-MapiVirtualDirectory -Server $item | Format-List InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : OAB" ; Get-OabVirtualDirectory -Server $item | Format-List InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : EWS" ; Get-WebServicesVirtualDirectory -Server $item | Format-List InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : ActiveSync" ; Get-ActiveSyncVirtualDirectory -Server $item | Format-List InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : PowerShell" ; Get-PowerShellVirtualDirectory -Server $item | Format-List InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : CAS" ; Get-ClientAccessService -Identity $item | Format-List Name,AutoDiscoverServiceInternalUri #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : AutoDiscover" ; Get-AutoDiscoverVirtualDirectory -Server $ServerShort | Format-List Name,InternalUrl,ExternalUrl #-AutoSize -Wrap 
    Write-Host -ForegroundColor Yellow -NoNewline "$ServerShort : Outlook Anywhere" ; Get-OutlookAnywhere -Server $ServerShort | Format-List InternalHostName,ExternalHostname #-AutoSize -Wrap 
}
