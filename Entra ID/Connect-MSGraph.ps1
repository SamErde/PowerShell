$global:TenantID = $null
<#
    .SYNOPSIS
        Connect your session to an Entra ID tenant with the Graph API.
    .DESCRIPTION
        This command will connect Microsoft.Graph to your Entra ID tenant.
        You can also directly call Connect-MgGraph if you require other options to connect
#>

# Compatible with Windows PowerShell 5.1
function Connect-MSGraphWP5 {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [ArgumentCompleter( {
            param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
            $Global:EnvironmentNames = (Get-MgEnvironment).Name; $EnvironmentNames
        } )]
        [ValidateScript({
            if ($_ -in $Global:EnvironmentNames) {
                $true
            } else {
                throw "$_ is not a valid environment name. Please use one of the following: $($Global:EnvironmentNames -join ', ')"
            }
        })]
        [string]$Environment
    )
    $Scopes = ('Directory.Read.All','Policy.Read.All','IdentityProvider.Read.All','Organization.Read.All','User.Read.All','EntitlementManagement.Read.All','UserAuthenticationMethod.Read.All','IdentityUserFlow.Read.All','APIConnectors.Read.All','AccessReview.Read.All','Agreement.Read.All','Policy.Read.PermissionGrant','PrivilegedAccess.Read.AzureResources','PrivilegedAccess.Read.AzureAD')
    Connect-MgGraph -TenantId $TenantId -Environment $Environment -Scopes $Scopes
    Get-MgContext
    $global:TenantID = (Get-MgContext).TenantId
}
# Add/save variable with Graph endpoint for the given environment.


# PowerShell Core 6+ usage
Class EnvironmentName : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $EnvironmentNames = (Get-MgEnvironment).Name
        return [string[]] $EnvironmentNames
    }
}

function Connect-MSGraph6 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet([EnvironmentName])]
        [string]$Environment
    )
    Connect-MgGraph -Environment $Environment
}


# Use with PowerShell 7
$global:Environments = Get-MgEnvironment

Class EnvironmentName : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $EnvironmentNames = ($global:Environments.Name)
        return [string[]] $EnvironmentNames
    }
}

function Connect-MSGraph6 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet([EnvironmentName])]
        [string]$Environment
    )
    Connect-MgGraph -Environment $Environment
    $global:GraphEndpoint = ( ($global:Environments).Where({$_.Name -eq $Environment}).GraphEndpoint )
    Write-Host -NoNewLine `n'You can reference $GraphEndpoint' "($GraphEndpoint) to query the Graph API in the $Environment environment.`n"
    return $global:GraphEndpoint | Out-Null
}


#Users with no UsageLocation
Connect-Graph -Scopes User.ReadWrite.All
Get-MgUser -Select Id,DisplayName,Mail,UserPrincipalName,UsageLocation,UserType | where { $_.UsageLocation -eq $null -and $_.UserType -eq 'Member' }

#Update users with no UsageLocation
Get-MgUser -Select Id,DisplayName,Mail,UserPrincipalName,UsageLocation,UserType | where { $_.UsageLocation -eq $null -and $_.UserType -eq 'Member' } | ForEach-Object { Update-MgUser -UserId $_.Id -UsageLocation "US"}
