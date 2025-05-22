<#
  AD DS PowerShell Test Module
 #>

<#
    NOTE: This was copied from the AD DS Deployment module and stored here for reference and study only.

    Change History:
    - Fix all instances of $null on the right side of the assignment to $null on the left side.

#>
$script:dsmodule = 'ADDSDeployment'
$script:dstype = 'Microsoft.DirectoryServices.Deployment.Tests.ADTestResult'
$script:configurationType = 'Microsoft.DirectoryServices.Deployment.Types.ConfigurationType'

function Get-_InternalADDSActiveDirectoryDomainNames() {
    param(
        [Parameter(Mandatory = $true)]
        [string]$forestOrDomain,
        [System.Management.Automation.PSCredential]$credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        Write-DirectoryEntryPropertyValue -forestOrDomain $forestOrDomain -searchRootCN 'Partitions' -property 'dnsroot' -filter '(&(objectClass=crossRef)(systemFlags=3))' -credential $credential
    }
}

function Get-_InternalADDSActiveDirectorySiteNames() {
    param(
        [Parameter(Mandatory = $true)]
        [string]$forestOrDomain,
        [System.Management.Automation.PSCredential]$credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        Write-DirectoryEntryPropertyValue -forestOrDomain $forestOrDomain -searchRootCN 'Sites' -property 'name' -filter '(objectClass=site)' -credential $credential
    }
}

function Invoke-_InternalADDSDoesDomainNamingContextExist {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Parameter(Mandatory = $true)]
        [string] $domainName
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        #check if domain name exists
        Write-Output([Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().DoesDomainNamingContextExist($configurationType, $domainName))
    }
}

function Invoke-_InternalADDSDoesDNSDelegationForThisMachineExistInParentZone {
    param(
        [bool] $forcedDemotion,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().DoesDnsDelegationForThisMachineExistInParentZone($forcedDemotion, $userName, $password, $userDomain) )
    }
}

function Get-_InternalADDSDatabaseFacts {
    param(
        [Parameter(Mandatory = $true)]
        [string] $sourcePath,
        [bool] $isReadOnly = $false
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }


        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetDatabaseInfo($sourcePath, $isReadOnly) )
    }
}


function Get-_InternalADDSAllowedRodcReplicationAccounts {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode = [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode]::Normal,
        [Parameter(Mandatory = $true)]
        [string] $serverName,
        [Parameter(Mandatory = $true)]
        [string] $domainDnsName,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        Write-Output([Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetAllowedRodcGroupSids($configurationType, $configurationMode, $serverName, $domainDnsName, $userName, $password, $userDomain))
    }
}

function Get-_InternalADDSDeniedRodcReplicationAccounts {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode = [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode]::Normal,
        [Parameter(Mandatory = $true)]
        [string] $serverName,
        [Parameter(Mandatory = $true)]
        [string] $domainDnsName,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        Write-Output([Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetDeniedRodcGroupSids($configurationType, $configurationMode, $serverName, $domainDnsName, $userName, $password, $userDomain))
    }
}

function Get-_InternalADDSDnsDelegationOptions {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode,
        [ValidateSet('False', 'True', 'NotSet', IgnoreCase = $true)]
        [string] $configDns = 'NotSet',
        [string] $newDomainDnsName,
        [string] $targetDomainDnsName,
        [bool] $isReadOnlyReplica = $false,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )
    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        Write-Output([Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetDnsDelegationCreationAndEditStatus($configurationType, $configurationMode, $configDns, $newDomainDnsName, $targetDomainDnsName, $isReadOnlyReplica, $userName, $password, $userDomain))
    }
}

function Get-_InternalADDSForestFunctionalLevel {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode = [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode]::Normal,
        [string] $domainDnsName,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetForestFunctionalLevel($configurationType, $configurationMode, $domainDnsName, $userName, $password, $userDomain) )
    }
}

function Get-_InternalADDSDefaultDNSOption {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode = [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode]::Normal,
        [string] $domainDnsName,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetDefaultDnsOption($configurationType, $configurationMode, $domainDnsName, $userName, $password, $userDomain) )
    }
}

function Get-_InternalADDSDefaultSiteName {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Parameter(Mandatory = $true)]
        [string] $domainDnsName,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetDefaultSiteName($configurationType, $domainDnsName, $userName, $password, $userDomain) )
    }
}

function Get-_InternalADDSExistingDCAccountInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string] $replicaDomain,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetExistingAccountForComputerInReplicaDomain($replicaDomain, $userName, $password, $userDomain) )
    }
}

function Invoke-_InternalADDSCanContactOtherDCsinDomain {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().CanDCContactAnotherDCInDomain() )
    }
}


function Get-_InternalADDSGeneratedNetbiosName {
    param(
        [Parameter(Mandatory = $true)]
        [string] $domainDnsName
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetGeneratedNetBiosName( $domainDnsName ) )
    }
}

function Get-_InternalADDSNDNCListWithNoOtherReplicas {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        $results = [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetNdncsHostedByDCWithNoOtherReplicas()
        foreach ( $result in $results ) {
            Write-Output( $result )
        }
    }
}

function Invoke-_InternalADDSIsDc {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        $result = [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().IsDC()
        Write-Output( $result )
    }
}

function Invoke-_InternalADDSIsDcpromoInProgress {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }
        $result = [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().IsDCPromotionInProgress()
        Write-Output( $result )
    }
}

function Invoke-_InternalADDSIsAdvertising {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        $computerName = [System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName()).HostName
        Import-Module -Name ActiveDirectory
        $dcObject = Get-ADDomainController -Discover
        $result = $False
        if ( ( $null -ne $dcObject ) -and ( [string]::Compare( $computerName, $dcObject.HostName, $True ) -eq 0 ) ) { $result = $True }
        Write-Output( $result )
    }
}

function Invoke-_InternalADDSIsRodcSupported {
    param(
        [string] $domainDnsName,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().IsRodcSupported($domainDnsName, $userName, $password, $userDomain) )
    }
}

function Invoke-_InternalEnsureADDSComponentInstallState {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }
        $result = [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().EnsureAddsComponentInstallState()
        Write-Output( $result )
    }
}

function Invoke-_InternalADDSIsRodc {
    param(
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().IsDCAnRodc($userName, $password, $userDomain) )
    }
}

function Invoke-_InternalIsLastFullDcInDomain {
    param(
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().IsLastFullDCInDomain($userName, $password, $userDomain) )
    }
}

function Invoke-_InternalADDSDoesDCHostOperationMasterRole {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetFsmoRolesHostedByDC() )
    }
}

function Get-_InternalADDSPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$envVariableName,
        [Parameter(Mandatory = $true)]
        [string]$folderPath
    )
    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        Write-Output( [IO.Path]::Combine( ( [Environment]::ExpandEnvironmentVariables( $envVariableName ) ), $folderPath ) )
    }
}

function New-DirectoryEntry() {
    param(
        [Parameter(Mandatory = $true)]
        [string] $path,
        [System.Management.Automation.PSCredential]$credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        [System.DirectoryServices.DirectoryEntry]$result = $null

        if ($credential -eq $null) {
            Write-Output( New-Object System.DirectoryServices.DirectoryEntry ($path) )
        } else {
            Write-Output( New-Object System.DirectoryServices.DirectoryEntry ($path, $credential.UserName, $credential.GetNetworkCredential().Password) )
        }
    }
}

function Test-_InternalADDSVerifyChild {
    param(
        [Parameter(Mandatory = $true)]
        [string] $parentDomain,
        [Parameter(Mandatory = $true)]
        [string] $leafDomain,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyChild($parentDomain, $leafDomain, $userName, $password, $userDomain) )
    }
}

# Needed?
function Test-_InternalADDSVerifyDemote {
    param(
        [bool] $isLastDC,
        [bool] $ignoreLastDCMismatch,
        [bool] $ignoreIsLastDnsServer,
        [bool] $retainDCMetadata,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $domain,
        [string] $replicaDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }
        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyDemote($isLastDC, $ignoreLastDCMismatch, $ignoreIsLastDnsServer, $retainDCMetadata, $userName, $password, $domain, $replicaDomain ) )
    }
}

function Test-_InternalADDSVerifyDnsConfigOptions {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode,
        [ValidateSet('False', 'True', 'NotSet', IgnoreCase = $true)]
        [string] $configDns = 'NotSet',
        [bool] $isDnsOnNet,
        [string] $targetDomain,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyDnsConfigOptions($configurationType, $configurationMode, $configDns, $isDnsOnNet, $targetDomain, $userName, $password, $userDomain) )
    }
}

function Test-_InternalADDSVerifyForestName {
    param(
        [Parameter(Mandatory = $true)]
        [string] $forestName
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        $result = [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyForestName($forestName)
        Write-Output( $result )
    }
}

function Test-_InternalADDSVerifyMachineAdminPassword {
    param(
        [System.Security.SecureString] $password
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyMachineAdminPassword($password) )
    }
}

function Test-_InternalADDSVerifyNetBiosName {
    param(
        [Parameter(Mandatory = $true)]
        [string] $domainDnsName,
        [string] $netbiosName
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyNetbiosName($domainDnsName, $netbiosName) )
    }
}

function Test-_InternalADDSVerifyPaths {
    param(
        [string] $dbPath,
        [string] $logPath,
        [string] $sysvolPath,
        [string] $replicationPath
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyPaths($dbPath, $logPath, $sysvolPath, $replicationPath) )
    }
}

function Test-_InternalADDSVerifyReplica {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode,
        [Parameter(Mandatory = $true)]
        [string] $targetDomain,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyReplica($configurationType, $configurationMode, $targetDomain, $userName, $password, $userDomain) )
    }
}

function Test-_InternalADDSVerifySafeModePassword {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode = [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode]::Normal,
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString] $safeModePassword,
        [string] $replicationDC,
        [string] $replicaDomain,
        [string] $userName,
        [System.Security.SecureString] $userPassword,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifySafeModePassword($configurationType, $configurationMode, $safeModePassword, $replicaDc, $replicaDomain, $userName, $userPassword, $userDomain) )
    }
}

function Test-_InternalADDSVerifyTree {
    param(
        [Parameter(Mandatory = $true)]
        [string] $newDomain,
        [Parameter(Mandatory = $true)]
        [string] $parentDomain,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyTree($newDomain, $parentDomain, $userName, $password, $userDomain) )
    }
}

function Test-_InternalADDSVerifyUserCredentialPermissions {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode,
        [string] $domainDnsName,
        [bool] $isReadOnlyReplica = $false,
        [string] $userName,
        [System.Security.SecureString] $password,
        [string] $userDomain
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output( [Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyUserCredentialPermissions($configurationType, $configurationMode, $domainDnsName, $isReadOnlyReplica, $userName, $password, $userDomain) )
    }
}

function Test-_InternalADDSVerifyForestUpgradeStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string] $server,
        [System.Management.Automation.PSCredential] $credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyForestUpgradeStatus($server, $credential))
    }
}

function Test-_InternalADDSVerifyDomainUpgradeStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string] $server,
        [System.Management.Automation.PSCredential] $credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyDomainUpgradeStatus($server, $credential))
    }
}

function Test-_InternalADDSVerifyRODCUpgradeStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string] $server,
        [System.Management.Automation.PSCredential] $credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyRODCUpgradeStatus($server, $credential))
    }
}

function Test-_InternalADDSVerifySchemaMasterOnline {
    param(
        [Parameter(Mandatory = $true)]
        [string] $domain,
        [System.Management.Automation.PSCredential] $credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifySchemaMasterOnline($domain, $credential))
    }
}

function Test-_InternalADDSVerifyInfrastructureMasterOnline {
    param(
        [Parameter(Mandatory = $true)]
        [string] $domain,
        [System.Management.Automation.PSCredential] $credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyInfrastructureMasterOnline($domain, $credential))
    }
}

function Test-_InternalADDSVerifyNamingMasterOnline {
    param(
        [Parameter(Mandatory = $true)]
        [string] $domain,
        [System.Management.Automation.PSCredential] $credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyNamingMasterOnline($domain, $credential))
    }
}

function Test-_InternalADDSVerifyADPrepCredential {
    param(
        [Parameter(ParameterSetName = 'configurationTypeSet')]
        [Parameter(ParameterSetName = 'defaultSet')]
        [Parameter(Mandatory = $true)]
        [string] $server,

        [Parameter(ParameterSetName = 'configurationTypeSet')]
        [Parameter(ParameterSetName = 'defaultSet')]
        [Parameter(Mandatory = $true)]
        [string] $domain,

        [Parameter(ParameterSetName = 'configurationTypeSet')]
        [Parameter(ParameterSetName = 'defaultSet')]
        [System.Management.Automation.PSCredential] $credential = $null,

        [Parameter(ParameterSetName = 'defaultSet')]
        [switch] $forestPrep,

        [Parameter(ParameterSetName = 'defaultSet')]
        [switch] $domainPrep,

        [Parameter(ParameterSetName = 'defaultSet')]
        [switch] $rodcPrep,

        [Parameter(ParameterSetName = 'configurationTypeSet')]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $type,

        [Parameter(ParameterSetName = 'configurationTypeSet')]
        [switch] $readOnlyReplica
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if (($null -eq ($dstype -as [type])) -or ($null -eq ($configurationType -as [type]))) { Import-Module $dsmodule }

        switch ($PSCmdlet.ParameterSetName) {
            'configurationTypeSet' {
                switch ($type) {
                    Replica {
                        $forestPrep = $true
                        $domainPrep = $true
                        $rodcPrep = $readOnlyReplica
                        break
                    }

                    Tree {}
                    Child {
                        $forestPrep = $true
                        $domainPrep = $false
                        $rodcPrep = $false
                        break
                    }

                    default {
                        $forestPrep = $false
                        $domainPrep = $false
                        $rodcPrep = $false
                        break
                    }
                }

                break
            }

            'defaultSet' {
                break
            }
        }

        Write-Output ([Microsoft.DirectoryServices.Deployment.Tests.Prerequisites]::CreateInstance().VerifyADPrepCredential($server, $domain, $credential, $forestPrep, $domainPrep, $rodcPrep, $false))
    }
}

# retrieve replication partner
function Get-_InternalADDSSuitableHelperDomainController {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode = [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode]::Normal,
        [Parameter(Mandatory = $true)]
        [string] $domain,
        [string] $site = $null,
        [switch] $readOnlyReplica,
        [System.Management.Automation.PSCredential]$credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetDefaultReplicationPartnerDC($configurationType, $configurationMode, $domain, $site, $readOnlyReplica, $credential))
    }
}

function Get-_InternalADDSDomainControllersInDomain {
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationType] $configurationType,
        [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode] $configurationMode = [Microsoft.DirectoryServices.Deployment.Types.ConfigurationMode]::Normal,
        [Parameter(Mandatory = $true)]
        [string] $domain,
        [bool] $isReadOnly = $false,
        [System.Management.Automation.PSCredential]$credential = $null
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        if ($null -eq ($dstype -as [type])) { Import-Module $dsmodule }

        Write-Output ([Microsoft.DirectoryServices.Deployment.DeepTasks.DeepTasks]::CreateInstance().GetDomainControllers($configurationType, $configurationMode, $domain, $isReadOnly, $credential))
    }
}

function Write-DirectoryEntryPropertyValue() {
    param(
        [Parameter(Mandatory = $true)]
        [string]$forestOrDomain,

        [Parameter(Mandatory = $true)]
        [string]$searchRootCN,

        [Parameter(Mandatory = $true)]
        [string]$property,

        [Parameter(Mandatory = $true)]
        [string]$filter,

        [System.Management.Automation.PSCredential]$credential = $null
    )

    Process {

        function DisposeObject($obj) {
            if ($null -ne $obj) {
                $obj.Dispose()
            }
        }

        trap {
            throw $_.Exception
            break
        }

        [string]$rootDSEPath = "LDAP://$forestOrDomain/RootDSE"
        [System.DirectoryServices.DirectoryEntry]$rootDE = New-DirectoryEntry -path $rootDSEPath -credential $credential
        if ($null -eq $rootDE.Properties) {
            $rootDE.RefreshCache()
        }

        [string]$configurationNamingContext = $rootDE.Properties['configurationNamingContext'].Value
        [string]$searchRootPath = "LDAP://$forestOrDomain/CN=$searchRootCN,$configurationNamingContext"

        [System.DirectoryServices.DirectoryEntry]$searchRootDE = New-DirectoryEntry -path $searchRootPath -credential $credential

        [System.DirectoryServices.DirectorySearcher]$directorySearcher = New-Object System.DirectoryServices.DirectorySearcher
        $directorySearcher.SearchRoot = $searchRootDE
        $directorySearcher.Filter = $filter
        $directorySearcher.PageSize = 500
        $suppressOutput = $directorySearcher.PropertiesToLoad.Add($property)
        [System.DirectoryServices.SearchResultCollection] $result = $directorySearcher.FindAll()

        foreach ($searchResult in $result) {
            $resultProperties = $searchResult.Properties
            $valueCollection = $resultProperties[$property]
            if ($null -ne $valueCollection) {
                [string]$propertyValue = $valueCollection[0]
                if ($null -ne $propertyValue) {
                    Write-Output $propertyValue
                }
            }
        }

        DisposeObject($directorySearcher)
        DisposeObject($searchRootDE)
        DisposeObject($rootDE)
    }
}

function Restart-_InternalADDSDeploymentTarget() {
    param(
    )

    Process {
        trap [Exception] {
            throw $_.Exception
            return
        }

        [System.Diagnostics.ProcessStartInfo]$startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = 'Shutdown.exe'
        $startInfo.Arguments = '/r /f /t 0'
        $startInfo.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($startInfo)
    }
}

Export-ModuleMember -Function Get-_InternalADDSActiveDirectoryDomainNames
Export-ModuleMember -Function Get-_InternalADDSActiveDirectorySiteNames
Export-ModuleMember -Function Invoke-_InternalADDSDoesDomainNamingContextExist
Export-ModuleMember -Function Get-_InternalADDSAllowedRodcReplicationAccounts
Export-ModuleMember -Function Get-_InternalADDSDatabaseFacts
Export-ModuleMember -Function Get-_InternalADDSDefaultDNSOption
Export-ModuleMember -Function Get-_InternalADDSDefaultSiteName
Export-ModuleMember -Function Get-_InternalADDSDeniedRodcReplicationAccounts
Export-ModuleMember -Function Get-_InternalADDSDnsDelegationOptions
Export-ModuleMember -Function Get-_InternalADDSExistingDCAccountInfo
Export-ModuleMember -Function Get-_InternalADDSForestFunctionalLevel
Export-ModuleMember -Function Get-_InternalADDSGeneratedNetbiosName
Export-ModuleMember -Function Get-_InternalADDSPath
Export-ModuleMember -Function Invoke-_InternalADDSDoesDCHostOperationMasterRole
Export-ModuleMember -Function Invoke-_InternalADDSDoesDNSDelegationForThisMachineExistInParentZone
Export-ModuleMember -Function Invoke-_InternalADDSIsDc
Export-ModuleMember -Function Invoke-_InternalADDSIsDcpromoInProgress
Export-ModuleMember -Function Invoke-_InternalADDSIsAdvertising
Export-ModuleMember -Function Invoke-_InternalADDSIsRodc
Export-ModuleMember -Function Invoke-_InternalIsLastFullDcInDomain
Export-ModuleMember -Function Invoke-_InternalADDSIsRodcSupported
Export-ModuleMember -Function Get-_InternalADDSNDNCListWithNoOtherReplicas
Export-ModuleMember -Function Invoke-_InternalADDSCanContactOtherDCsinDomain
Export-ModuleMember -Function Test-_InternalADDSVerifyChild
Export-ModuleMember -Function Test-_InternalADDSVerifyDemote
Export-ModuleMember -Function Test-_InternalADDSVerifyDnsConfigOptions
Export-ModuleMember -Function Test-_InternalADDSVerifyForestName
Export-ModuleMember -Function Test-_InternalADDSVerifyMachineAdminPassword
Export-ModuleMember -Function Test-_InternalADDSVerifyNetBiosName
Export-ModuleMember -Function Test-_InternalADDSVerifyPaths
Export-ModuleMember -Function Test-_InternalADDSVerifyReplica
Export-ModuleMember -Function Test-_InternalADDSVerifySafeModePassword
Export-ModuleMember -Function Test-_InternalADDSVerifyTree
Export-ModuleMember -Function Test-_InternalADDSVerifyUserCredentialPermissions
Export-ModuleMember -Function Test-_InternalADDSVerifyForestUpgradeStatus
Export-ModuleMember -Function Test-_InternalADDSVerifyDomainUpgradeStatus
Export-ModuleMember -Function Test-_InternalADDSVerifyRODCUpgradeStatus
Export-ModuleMember -Function Test-_InternalADDSVerifySchemaMasterOnline
Export-ModuleMember -Function Test-_InternalADDSVerifyInfrastructureMasterOnline
Export-ModuleMember -Function Test-_InternalADDSVerifyNamingMasterOnline
Export-ModuleMember -Function Test-_InternalADDSVerifyADPrepCredential
Export-ModuleMember -Function Get-_InternalADDSDomainControllersInDomain
Export-ModuleMember -Function Get-_InternalADDSSuitableHelperDomainController
Export-ModuleMember -Function Invoke-_InternalEnsureADDSComponentInstallState
Export-ModuleMember -Function Restart-_InternalADDSDeploymentTarget
