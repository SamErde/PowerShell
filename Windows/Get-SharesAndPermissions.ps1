[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ComputerName,

    [Parameter()]
    [System.Management.Automation.PSCredential]
    $Credential
)

Function Get-SharePermissions {
    <#
	    .Synopsis
		    This function retrieves share permissions from a remote computer.
        .Description
          This function returns user name and domain of users and permission
          type and level on a remote share.  It accepts alternate credentials
          for remote connections.
        .Example
            Get-SharePermissions -ComputerName WindowsServer -ShareName Test
            Returns permissions for \\WindowsServer\Test
	    .Example
		    Get-SharePermissions -ComputerName WindowsServer -ShareName Test -Credential (Get-Credential)
	    .Parameter ComputerName
            The remote system to connect to
        .Parameter ShareName
            The name of the share to retrieve permissions for.
        .Parameter Credential
		    The alternate credentials used to connect if the logged on user does not have access
	    .Notes
		    NAME: Example-
		    AUTHOR: Richard Perkins
		    LASTEDIT: 04/11/2016 15:20:52
		    KEYWORDS: Share, Permissions
    #>

    # Adjusted code from https://gallery.technet.microsoft.com/scriptcenter/List-Share-Permissions-83f8c419
    param(
        [parameter(Mandatory = $True)]
        [string]$ComputerName,

        [parameter(Mandatory = $True)]
        [string]$ShareName,

        [PSCredential]$Credential
    )
    $CimParameters = @{
        ClassName    = 'Win32_LogicalShareSecuritySetting'
        ComputerName = $ComputerName
    }

    if ($Credential) {
        $CimParameters['Credential'] = $Credential
    }

    $ShareSec = Get-CimInstance @CimParameters | Where-Object { $_.Name -eq $ShareName }

    if ($null -eq $ShareSec) {
        Write-Warning "Unable to find share '$ShareName' on '$ComputerName'."
        return
    }

    $SecurityDescriptor = (Invoke-CimMethod -InputObject $ShareSec -MethodName GetSecurityDescriptor -ErrorAction Stop).Descriptor

    Try {
        $SecurityDescriptor.DACL | ForEach-Object {
            $UserName = $_.Trustee.Name
            If ($Null -ne $_.Trustee.Domain) { $UserName = "$($_.Trustee.Domain)\$UserName" }
            If ($Null -eq $_.Trustee.Name) { $UserName = $_.Trustee.SIDString }

            [PSCustomObject]@{
                UserName          = $UserName
                AccessMask        = $_.AccessMask
                SharePermission   = switch ([int]$_.AccessMask) {
                    1179817 { 'Read' }
                    1245631 { 'Change' }
                    2032127 { 'FullControl' }
                    default { "Custom ($($_.AccessMask))" }
                }
                AccessControlType = [System.Security.AccessControl.AccessControlType]$_.AceType
            }
        }
    } Catch {
        Write-Warning "Unable to obtain permissions for '$ShareName'. $_"
    }
} #End Function Get-SharePermissions

<#
0 - Disk drive
1 - Print queue
2 - Device
3 - IPC
2147483648 - Disk drive (Administrative share)
2147483649 - Print queue (Administrative share)
2147483650 - Device (Administrative share)
2147483651 - IPC (Administrative share)
#>

$CimParameters = @{
    ClassName    = 'Win32_Share'
    ComputerName = $ComputerName
}

if ($Credential) {
    $CimParameters['Credential'] = $Credential
}

$Shares = Get-CimInstance @CimParameters
$AdminShares = $Shares | Where-Object { ($_.Type -ge 2147483648) -AND ($_.Type -le 2147483651) }

$ShareList = @()

$Shares | Where-Object { $_.Type -eq 0 } | ForEach-Object {
    $ShareDrive = ($_.Path | Split-Path -Qualifier) + '\'
    $AdminUncPath = Join-Path -Path (Join-Path -Path $('\\' + $ComputerName) -ChildPath $(($AdminShares | Where-Object { $_.Path -eq $(($ShareDrive | Split-Path -Qualifier) + '\') }).Name)) -ChildPath (Split-Path $_.Path -NoQualifier)

    $Share = $_ | Select-Object -Property @{Name = 'AdminUncPath'; Expression = { $AdminUncPath } },
    @{Name = 'AllowMaximum'; Expression = { $_.AllowMaximum } }, @{Name = 'Caption'; Expression = { $_.Caption } },
    @{Name = 'ComputerName'; Expression = { $_.PSComputerName } }, @{Name = 'Description'; Expression = { $_.Description } },
    @{Name = 'Drive'; Expression = { $ShareDrive } }, @{Name = 'MaximumAllowed'; Expression = { $_.MaximumAllowed } },
    @{Name = 'Name'; Expression = { $_.Name } }, @{Name = 'NtfsAcl'; Expression = { $($AdminUncPath | Get-Acl) } },
    @{Name = 'Path'; Expression = { $_.Path } }, @{Name = 'ShareAcl'; Expression = { $(Get-SharePermissions -ComputerName $ComputerName -ShareName $_.Name -Credential $Credential) } },
    @{Name = 'Status'; Expression = { $_.Status } }, @{Name = 'Type'; Expression = { $_.Type } }

    $ShareList += $Share

    Clear-Variable -Name Share
    Clear-Variable -Name ShareDrive
    Clear-Variable -Name AdminUncPath
}

$ShareList
