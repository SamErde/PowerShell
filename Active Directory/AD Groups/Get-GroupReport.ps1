<#
  This script will enumerate all group objects in a Domain, providing both a
  high level overview and a full report based on the values of the following
  attributes:
  - name
  - distinguishedname
  - samaccountname
  - mail
  - grouptype
  - displayname
  - description
  - member
  - memberof
  - info
  - isCriticalSystemObject
  - admincount
  - managedBy
  - expirationtime
  - whencreated
  - whenchanged
  - sidhistory
  - objectsid
  - proxyAddresses
  - legacyExchangeDN
  - mailNickName
  - reportToOriginator
  - gidNumber
  - msSFU30Name
  - msSFU30NisDomain

  We further derive:
  - The Parent OU from the distinguishedname attribute.
  - The GroupCategory and GroupScope from the grouptype attribute.
  - The MemberCount from the member attribute.
  - MailEnabled from proxyAddresses, legacyExchangeDN, mailNickName, and
    reportToOriginator. reportToOriginator must be set to TRUE. This is
    not well documented.
  - Expired from the expirationtime attribute.
  - Conflict from the name and samaccountname attributes.
  - UnixEnabled from gidnumber, mssfu30name, mssfu30nisdomain.
  - Exclude:
    When reviewing groups it's important to flag the ones that are marked as
    Critical System Objects where their isCriticalSystemObject attribute is
    set to True, Protected Objects (AdminSDHolder) where their adminCount
    attribute is set to 1, and various other important groups that should not
    be removed. To be able to capture the "other" groups we place them into
    the $ExclusionGroups and $ExclusionOUs arrays.

  Now, you may have groups marked by the AdminSDHolder that no longer
  require protection. It happens due to group nesting, and is not something
  that's automatically removed when the group falls out of scope. Therefore
  it's still marked as protected. This is often unintentional and typically
  misunderstood. You'll need to review each one to unblock inheritance and
  clear the adminCount attribute where they fall out of scope. However, I
  recommend using a script written by Tony Murray to clean up the AdminSDHolder:
  http://www.open-a-socket.com/index.php/2013/09/11/cleaning-up-adminsdholder-orphans/

  Further information about the AdminSDHolder can be found here:
  - http://social.technet.microsoft.com/wiki/contents/articles/22331.adminsdholder-protected-groups-and-security-descriptor-propagator.aspx
  - http://technet.microsoft.com/en-us/magazine/2009.09.sdadminholder.aspx
  - http://www.selfadsi.org/extended-ad/ad-permissions-adminsdholder.htm
  - http://blogs.technet.com/b/askds/archive/2009/05/07/five-common-questions-about-adminsdholder-and-sdprop.aspx

  I have seen situations where the adminCount attribute is set to 5. Whilst
  this is an invalid and undocumented value the adminCount attribute is
  4 bytes (32 bits) in size. Valid values are 0 (disabled), 1 (enabled), or
  not set (disabled - default). So it's simply enabled or disabled based on
  the least significant bit. Converting 5 into binary, it's least significant
  bit is 1. Therefore, we take a setting of 5 to mean that it's enabled.

  We group together the following 4 attributes to determine if a group is
  mail-enabled: proxyAddresses, legacyExchangeDN, mailNickName, and
  reportToOriginator:
  - http://pmoreland.blogspot.com.au/2013/03/creating-mail-contacts-and-distribution.html

  Groups whose name contains CNF: and/or sAMAccountName contains $Duplicate
  means that it's a duplicate account caused by conflicting/duplicate objects.
  This typically occurs when objects are created on different Read Write Domain
  Controllers at nearly the same time. After replication kicks in and those
  conflicting/duplicate objects replicate to other Read Write Domain Controllers,
  Active Directory replication applies a conflict resolution mechanism to ensure
  every object is and remains unique. You can't just delete the conflicting/
  duplicate objects, as these may often be in use. You need to merge the group
  membership and ensure the valid group is correctly applied to the resource.
  Then you can confidently delete the conflicting/duplicate group.

  A nice way to manage groups it to set their expirationTime attribute. This
  will give us the ability to implement a nice lifecycle management process.
  You can go one step further and add a user or mail enabled security group to
  the managedBy attribute. This will give us the ability to implement some
  workflow when the group is x days before expiring.

  Syntax examples:

  - To execute the script in the current Domain:
      Get-GroupReport.ps1

  - To execute the script against a trusted Domain:
      Get-GroupReport.ps1 -TrustedDomain mydemosthatrock.com

  Script Name: Get-GroupReport.ps1
  Release 1.7
  Written by Jeremy@jhouseconsulting.com 16/12/2014
  Modified by Jeremy@jhouseconsulting.com 05/01/2015

#>
#-------------------------------------------------------------
param([String]$TrustedDomain, [switch]$verbose)

Set-StrictMode -Version 2.0

if ($verbose.IsPresent) {
    $VerbosePreference = 'Continue'
    Write-Verbose 'Verbose Mode Enabled'
} Else {
    $VerbosePreference = 'SilentlyContinue'
}

#-------------------------------------------------------------

# Set this to the OU structure where the you want to search to
# start from. Do not add the Domain DN. If you leave it blank,
# the script will start from the root of the domain.
$OUStructureToProcess = ''

# Set the name of the attribute you want to populate for objects
# to be evaluated as a stale or non-stale object.
$ExcludeAttribute = 'comment'
[void]$ExcludeAttribute

# Set the text within the $ExcludeAttribute that you want to use
# to evaluate if the object should be excluded from the stale
# object collection.
$ExcludeText = 'Decommission=False'
[void]$ExcludeText

# Set this to the delimiter for the CSV output
$Delimiter = ','

# Set this to remove the double quotes from each value within the
# CSV.
$RemoveQuotesFromCSV = $False

# Set this value to true if you want to see the progress bar.
$ProgressBar = $True

# Although some of the default groups are not marked as a Critical
# System Objects or Protected Objects (AdminSDHolder) they must
# still be excluded from deletion as a good practice.
# http://technet.microsoft.com/en-us/library/dn579255.aspx
# On top of this we exclude the RTC groups as part of OCS/Lync and
# also the "Microsoft Exchange" OUs.

$ExclusionGroups = @(
    'DnsAdmins', `
        'DnsUpdateProxy', `
        'DHCP Users', `
        'DHCP Administrators', `
        'Offer Remote Assistance Helpers', `
        'TelnetClients', `
        'IIS_WPG', `
        'Access Control Assistance Operators', `
        'Cloneable Domain Controllers', `
        'Hyper-V Administrators', `
        'Protected Users', `
        'RDS Endpoint Servers', `
        'RDS Management Servers', `
        'RDS Remote Access Servers', `
        'Remote Management Users', `
        'WinRMRemoteWMIUsers_', `
        'RTC*'
)

$ExclusionOUs = @(
    '*Microsoft Exchange System Objects*'
    '*Microsoft Exchange Security Groups*'
)

#-------------------------------------------------------------

$invalidChars = [io.path]::GetInvalidFileNamechars()
$datestampforfilename = ((Get-Date -Format s).ToString() -replace "[$invalidChars]", '-')

# Get the script path
$ScriptPath = { Split-Path $MyInvocation.ScriptName }
$ReferenceFileFull = $(&$ScriptPath) + "\GroupReport-Full-$($datestampforfilename).csv"
$ReferenceFileSummary = $(&$ScriptPath) + "\GroupReport-Summary-$($datestampforfilename).csv"
$ReferenceFileSummaryTotals = $(&$ScriptPath) + "\GroupReport-Summary-Totals-$($datestampforfilename).csv"

if (Test-Path -Path $ReferenceFileFull) {
    Remove-Item $ReferenceFileFull -Force -Confirm:$false
}
if (Test-Path -Path $ReferenceFileSummary) {
    Remove-Item $ReferenceFileSummary -Force -Confirm:$false
}
if (Test-Path -Path $ReferenceFileSummaryTotals) {
    Remove-Item $ReferenceFileSummaryTotals -Force -Confirm:$false
}

if ([String]::IsNullOrEmpty($TrustedDomain)) {
    # Get the Current Domain Information
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
} else {
    $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('domain', $TrustedDomain)
    Try {
        $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)
    } Catch [exception] {
        Write-Host -ForegroundColor red $_.Exception.Message
        Exit
    }
}

# Get AD Distinguished Name
$DomainDistinguishedName = $Domain.GetDirectoryEntry() | Select-Object -ExpandProperty DistinguishedName

If ($OUStructureToProcess -eq '') {
    $ADSearchBase = $DomainDistinguishedName
} else {
    $ADSearchBase = $OUStructureToProcess + ',' + $DomainDistinguishedName
}

$TotalGroupsProcessed = 0
$GroupCount = 0
$GlobalDistributionGroups = 0
$DomainLocalDistributionGroups = 0
$UniversalDistributionGroups = 0
$GlobalSecurityGroups = 0
$DomainLocalSecurityGroups = 0
$BuiltinLocalSecurityGroups = 0
$UniversalSecurityGroups = 0
$UnrecognisedGroupTypes = 0
$GroupsHashTable = @{}
$TotalNoMembers = 0
$TotalMailEnabledObjects = 0
$TotalMailEnabledDistributionGroups = 0
$TotalCriticalSystemObjects = 0
$TotalProtectedObjects = 0
$TotalExcludedObjects = 0
$TotalToSubtract = 0
$TotalExpiredObjects = 0
$TotalConflictingObjects = 0
$TotalWithSIDHistory = 0
$TotalUnixEnabledObjects = 0

# Create an LDAP search for all groups
$ADFilter = '(objectClass=group)'

# There is a known bug in PowerShell requiring the DirectorySearcher
# properties to be in lower case for reliability.
$ADPropertyList = @('name', 'distinguishedname', 'samaccountname', 'mail', 'grouptype', `
        'displayname', 'description', 'member', 'memberof', 'info', `
        'isCriticalSystemObject', 'admincount', 'managedBy', 'objectsid', `
        'expirationtime', 'whencreated', 'whenchanged', 'sidhistory', `
        'proxyaddresses', 'legacyexchangedn', 'mailnickname', `
        'reporttooriginator', 'gidnumber', 'mssfu30name', 'mssfu30nisdomain')
$ADScope = 'SUBTREE'
$ADPageSize = 1000
$ADSearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($ADSearchBase)")
$ADSearcher = New-Object System.DirectoryServices.DirectorySearcher
$ADSearcher.SearchRoot = $ADSearchRoot
$ADSearcher.PageSize = $ADPageSize
$ADSearcher.Filter = $ADFilter
$ADSearcher.SearchScope = $ADScope
if ($ADPropertyList) {
    foreach ($ADProperty in $ADPropertyList) {
        [Void]$ADSearcher.PropertiesToLoad.Add($ADProperty)
    }
}
Try {
    Write-Host -ForegroundColor Green "`nPlease be patient whilst the script retrieves all group objects and specified attributes..."
    $colResults = $ADSearcher.Findall()
    # Dispose of the search and results properly to avoid a memory leak
    $ADSearcher.Dispose()
    $GroupCount = $colResults.Count
} Catch {
    $GroupCount = 0
    Write-Host -ForegroundColor red "The $ADSearchBase structure cannot be found!"
}
if ($GroupCount -ne 0) {

    Write-Host -ForegroundColor Green "`nProcessing $GroupCount group objects in the $domain Domain..."

    $colResults | ForEach-Object {
        $group = $_.GetDirectoryEntry()

        $Name = $($group.Name)
        $ParentOU = $($group.DistinguishedName) -split '(?<![\\]),'
        $ParentOU = $ParentOU[1..$($ParentOU.Count - 1)] -join ','

        switch ($($group.GroupType)) {
            2 {
                $GroupCategory = 'Distribution'
                $GroupScope = 'Global'
                $GlobalDistributionGroups = $GlobalDistributionGroups + 1
                Break
            }
            4 {
                $GroupCategory = 'Distribution'
                $GroupScope = 'Domain Local'
                $DomainLocalDistributionGroups = $DomainLocalDistributionGroups + 1
                Break
            }
            8 {
                $GroupCategory = 'Distribution'
                $GroupScope = 'Universal'
                $UniversalDistributionGroups = $UniversalDistributionGroups + 1
                Break
            }
            -2147483646 {
                $GroupCategory = 'Security'
                $GroupScope = 'Global'
                $GlobalSecurityGroups = $GlobalSecurityGroups + 1
                Break
            }
            -2147483644 {
                $GroupCategory = 'Security'
                $GroupScope = 'Domain Local'
                $DomainLocalSecurityGroups = $DomainLocalSecurityGroups + 1
                Break
            }
            -2147483643 {
                $GroupCategory = 'Security'
                $GroupScope = 'Builtin Local'
                $BuiltinLocalSecurityGroups = $BuiltinLocalSecurityGroups + 1
                Break
            }
            -2147483640 {
                $GroupCategory = 'Security'
                $GroupScope = 'Universal'
                $UniversalSecurityGroups = $UniversalSecurityGroups + 1
                Break
            }
            default {
                $GroupCategory = 'Unrecognised'
                $GroupScope = 'Unrecognised'
                $UnrecognisedGroupTypes = $UnrecognisedGroupTypes + 1
            }

        }

        $MemberCount = 0
        If (($group.Member | Measure-Object).Count -gt 0) {
            $group.Member | ForEach-Object {
                $MemberCount = $MemberCount + 1
            }
        }
        If ($MemberCount -eq 0) { $TotalNoMembers = $TotalNoMembers + 1 }

        $MailEnabled = $False
        If (($group.proxyaddresses | Measure-Object).Count -gt 0 -AND
        ($group.legacyexchangedn | Measure-Object).Count -gt 0 -AND
        ($group.mailnickname | Measure-Object).Count -gt 0 -AND
            $group.reporttooriginator -eq $True) {
            $MailEnabled = $True
            $TotalMailEnabledObjects = $TotalMailEnabledObjects + 1
            If ($GroupCategory -eq 'Distribution') {
                $TotalMailEnabledDistributionGroups = $TotalMailEnabledDistributionGroups + 1
            }
        }

        $UnixEnabled = $False
        If (($group.gidnumber | Measure-Object).Count -gt 0 -AND
        ($group.mssfu30name | Measure-Object).Count -gt 0 -AND
        ($group.mssfu30nisdomain | Measure-Object).Count -gt 0) {
            $UnixEnabled = $True
            $TotalUnixEnabledObjects = $TotalUnixEnabledObjects + 1
        }

        If ($group.isCriticalSystemObject -eq $True) { $TotalCriticalSystemObjects = $TotalCriticalSystemObjects + 1 }

        If (($group.adminCount | Measure-Object).Count -gt 0) {
            # Use the bitwise-AND (-bAnd) operator to determine if the least significant bit is set (1) or clear (0)
            $AdminCount = ($($group.adminCount) -band 00000001)
            If ($AdminCount -eq '1') { $TotalProtectedObjects = $TotalProtectedObjects + 1 }
        } Else {
            $AdminCount = ''
        }

        $Exclude = $False
        ForEach ($ExclusionGroup in $ExclusionGroups) {
            If ($Name -Like $ExclusionGroup) {
                $Exclude = $True
            }
        }
        ForEach ($ExclusionOU in $ExclusionOUs) {
            If ($ParentOU -Like $ExclusionOU) {
                $Exclude = $True
            }
        }
        If ($Exclude) { $TotalExcludedObjects = $TotalExcludedObjects + 1 }

        $Conflict = $False
        If ($Name -Like '*CNF:*' -OR $group.sAMAccountName -Like "`$Duplicate*") {
            # Replace the Line Feed character in the name so that it's a nicely represented string.
            $Name = $Name -replace "`n", ''
            $Conflict = $True
            $TotalConflictingObjects = $TotalConflictingObjects + 1
        }

        If ($MemberCount -eq 0 -AND ($group.isCriticalSystemObject -eq $True -OR $AdminCount -eq '1' -OR $Exclude)) { $TotalToSubtract = $TotalToSubtract + 1 }

        $SIDHistoryCount = 0
        If (($group.sidhistory | Measure-Object).Count -gt 0) {
            $group.sidhistory | ForEach-Object {
                $SIDHistoryCount = $SIDHistoryCount + 1
            }
            $TotalWithSIDHistory = $TotalWithSIDHistory + 1
        }

        $WhenCreated = $group.whencreated[0]

        $WhenChanged = $group.whenchanged[0]

        $ExpirationTime = $group.expirationtime[0]
        $Expired = $False
        If ($ExpirationTime -ne $NULL -AND $ExpirationTime -lt (Get-Date)) {
            $Expired = $True
            $TotalExpiredObjects = $TotalExpiredObjects + 1
        }

        If (($group.info | Measure-Object).Count -gt 0) {
            $notes = $($group.info)
            $notes = $notes -replace "`r`n", '|'
        } else {
            $notes = ''
        }

        # Get SID
        $stringSID = (New-Object System.Security.Principal.SecurityIdentifier($group.objectsid[0], 0)).Value

        $FullGroupType = "$GroupScope $GroupCategory Group"
        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -MemberType NoteProperty -Name 'GroupType' -Value $FullGroupType

        # Create a hashtable to capture a count of each Group Type
        If (!($GroupsHashTable.ContainsKey($FullGroupType))) {
            $TotalCount = 1
            $NoMembersCount = 0
            $MailEnabledCount = 0
            $MailDisabledCount = 0
            $UnixEnabledCount = 0
            $CriticalSystemObjectCount = 0
            $ProtectedObjectCount = 0
            $ExcludeObjectCount = 0
            $ExpiredObjectCount = 0
            $ConflictCount = 0
            $ContainSIDHistoryCount = 0
            If ($MemberCount -eq 0) { $NoMembersCount = 1 }
            If ($MailEnabled) {
                $MailEnabledCount = 1
            } Else {
                $MailDisabledCount = 1
            }
            If ($UnixEnabled) {
                $UnixEnabledCount = 1
            }
            If ($group.isCriticalSystemObject -eq $True) { $CriticalSystemObjectCount = 1 }
            If ($AdminCount -eq '1') { $ProtectedObjectCount = 1 }
            If ($Exclude) { $ExcludeObjectCount = 1 }
            If ($Expired) { $ExpiredObjectCount = 1 }
            If ($Conflict) { $ConflictCount = 1 }
            If ($SIDHistoryCount -ne 0) { $ContainSIDHistoryCount = 1 }
            $obj | Add-Member -MemberType NoteProperty -Name 'Total' -Value $TotalCount
            $obj | Add-Member -MemberType NoteProperty -Name 'No_Members' -Value $NoMembersCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Mail_Enabled' -Value $MailEnabledCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Mail_Disabled' -Value $MailDisabledCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Unix_Enabled' -Value $UnixEnabledCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Critical_System' -Value $CriticalSystemObjectCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Protected' -Value $ProtectedObjectCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Conflicting' -Value $ConflictCount
            $obj | Add-Member -MemberType NoteProperty -Name 'SIDHistory' -Value $ContainSIDHistoryCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Expired' -Value $ExpiredObjectCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Excluded' -Value $ExcludeObjectCount
            $GroupsHashTable = $GroupsHashTable + @{$FullGroupType = $obj }
        } else {
            $value = $GroupsHashTable.Get_Item($FullGroupType)
            $TotalCount = $value.Total + 1
            $NoMembersCount = $value.No_Members
            $MailEnabledCount = $value.Mail_Enabled
            $MailDisabledCount = $value.Mail_Disabled
            $UnixEnabledCount = $value.Unix_Enabled
            $CriticalSystemObjectCount = $value.Critical_System
            $ProtectedObjectCount = $value.Protected
            $ExcludeObjectCount = $value.Excluded
            $ExpiredObjectCount = $value.Expired
            $ConflictCount = $value.Conflicting
            $ContainSIDHistoryCount = $value.SIDHistory
            If ($MemberCount -eq 0) { $NoMembersCount = $NoMembersCount + 1 }
            If ($MailEnabled) {
                $MailEnabledCount = $MailEnabledCount + 1
            } Else {
                $MailDisabledCount = $MailDisabledCount + 1
            }
            If ($UnixEnabled) {
                $UnixEnabledCount = $UnixEnabledCount + 1
            }
            If ($group.isCriticalSystemObject -eq $True) { $CriticalSystemObjectCount = $CriticalSystemObjectCount + 1 }
            If ($AdminCount -eq '1') { $ProtectedObjectCount = $ProtectedObjectCount + 1 }
            If ($Exclude) { $ExcludeObjectCount = $ExcludeObjectCount + 1 }
            If ($Expired) { $ExpiredObjectCount = $ExpiredObjectCount + 1 }
            If ($Conflict) { $ConflictCount = $ConflictCount + 1 }
            If ($SIDHistoryCount -ne 0) { $ContainSIDHistoryCount = $ContainSIDHistoryCount + 1 }
            $obj | Add-Member -MemberType NoteProperty -Name 'Total' -Value $TotalCount
            $obj | Add-Member -MemberType NoteProperty -Name 'No_Members' -Value $NoMembersCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Mail_Enabled' -Value $MailEnabledCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Mail_Disabled' -Value $MailDisabledCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Unix_Enabled' -Value $UnixEnabledCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Critical_System' -Value $CriticalSystemObjectCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Protected' -Value $ProtectedObjectCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Conflicting' -Value $ConflictCount
            $obj | Add-Member -MemberType NoteProperty -Name 'SIDHistory' -Value $ContainSIDHistoryCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Expired' -Value $ExpiredObjectCount
            $obj | Add-Member -MemberType NoteProperty -Name 'Excluded' -Value $ExcludeObjectCount
            $GroupsHashTable.Set_Item($FullGroupType, $obj)
        }
        $obj = $Null

        $obj = New-Object -TypeName PSObject
        $obj | Add-Member -MemberType NoteProperty -Name 'Name' -Value $Name
        $obj | Add-Member -MemberType NoteProperty -Name 'ParentOU' -Value $ParentOU
        $obj | Add-Member -MemberType NoteProperty -Name 'sAMAccountName' -Value $($group.sAMAccountName)
        $obj | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $($group.displayname)
        $obj | Add-Member -MemberType NoteProperty -Name 'Description' -Value $($group.description)
        $obj | Add-Member -MemberType NoteProperty -Name 'MemberCount' -Value $MemberCount
        $obj | Add-Member -MemberType NoteProperty -Name 'GroupCategory' -Value $GroupCategory
        $obj | Add-Member -MemberType NoteProperty -Name 'GroupScope' -Value $GroupScope
        $obj | Add-Member -MemberType NoteProperty -Name 'Mail' -Value $($group.mail)
        $obj | Add-Member -MemberType NoteProperty -Name 'MailEnabled' -Value $MailEnabled
        $obj | Add-Member -MemberType NoteProperty -Name 'isCriticalSystemObject' -Value $($group.isCriticalSystemObject)
        $obj | Add-Member -MemberType NoteProperty -Name 'AdminCount' -Value $($group.adminCount)
        $obj | Add-Member -MemberType NoteProperty -Name 'Exclude' -Value $Exclude
        $obj | Add-Member -MemberType NoteProperty -Name 'Expired' -Value $Expired
        $obj | Add-Member -MemberType NoteProperty -Name 'Conflicting' -Value $Conflict
        $obj | Add-Member -MemberType NoteProperty -Name 'managedBy' -Value $($group.managedBy)
        $obj | Add-Member -MemberType NoteProperty -Name 'ExpirationTime' -Value $ExpirationTime
        $obj | Add-Member -MemberType NoteProperty -Name 'WhenChanged' -Value $WhenChanged
        $obj | Add-Member -MemberType NoteProperty -Name 'WhenCreated' -Value $WhenCreated
        $obj | Add-Member -MemberType NoteProperty -Name 'SIDHistoryCount' -Value $SIDHistoryCount
        $obj | Add-Member -MemberType NoteProperty -Name 'UnixEnabled' -Value $UnixEnabled
        $obj | Add-Member -MemberType NoteProperty -Name 'GIDNumber' -Value $($group.gidnumber)
        $obj | Add-Member -MemberType NoteProperty -Name 'info' -Value $notes
        $obj | Add-Member -MemberType NoteProperty -Name 'objectsid' -Value $stringSID

        # PowerShell V2 doesn't have an Append parameter for the Export-Csv cmdlet. Out-File does, but it's
        # very difficult to get the formatting right, especially if you want to use quotes around each item
        # and add a delimeter. However, we can easily do this by piping the object using the ConvertTo-Csv,
        # Select-Object and Out-File cmdlets instead.
        if ($PSVersionTable.PSVersion.Major -gt 2) {
            $obj | Export-Csv -Path "$ReferenceFileFull" -Append -Delimiter $Delimiter -NoTypeInformation -Encoding ASCII
        } Else {
            if (!(Test-Path -Path $ReferenceFileFull)) {
                $obj | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -First 1 | Out-File -Encoding ascii -FilePath "$ReferenceFileFull"
            }
            $obj | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -Skip 1 | Out-File -Encoding ascii -FilePath "$ReferenceFileFull" -Append -NoClobber
        }
        $obj = $Null

        $TotalGroupsProcessed ++
        If ($ProgressBar) {
            Write-Progress -Activity 'Processing Groups' -Status ('Name: {0}' -f $Name) -PercentComplete (($TotalGroupsProcessed / $GroupCount) * 100)
        }

    }

    # Dispose of the search and results properly to avoid a memory leak
    $colResults.Dispose()

    # Remove the quotes from the output file.
    If ($RemoveQuotesFromCSV) {
    (Get-Content "$ReferenceFileFull") | ForEach-Object { $_ -replace '"', '' } | Out-File "$ReferenceFileFull" -Fo -En ascii
    }

    Write-Host -ForegroundColor Green "`nA breakdown of the $GroupCount Group Objects in the $domain Domain:"

    $Output = $GroupsHashTable.values | ForEach-Object { $_ } | ForEach-Object { $_ } | Sort-Object GroupType -Descending
    # Auto-sized tables are by default limited to the width of your screen buffer. So to
    # ensure all columns of the table are displayed we force it to 4096 characters. I also
    # find that the Format-Table cmdlet will output a maximum of 10 columns by default, so
    # you must use the "Property" parameter and set it to *.
    $Output | Format-Table -Property * -AutoSize | Out-String -Width 4096

    # Write-Output $Output | Format-Table
    $Output | Export-Csv -Path "$ReferenceFileSummary" -Delimiter $Delimiter -NoTypeInformation

    # Remove the quotes
    If ($RemoveQuotesFromCSV) {
    (Get-Content "$ReferenceFileSummary") | ForEach-Object { $_ -replace '"', '' } | Out-File "$ReferenceFileSummary" -Fo -En ascii
    }

    # Note that for the summary output I went with a hashtable instead of binding multiple objects together.
    # Whilst some of the code may seem excessive and repetitive, I found this the simplest method to achieve
    # the desired output.
    $SummaryHashTable = @{}
    $Item = 0

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($GlobalDistributionGroups / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Global Distribution Groups'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $GlobalDistributionGroups
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Global Distribution Groups' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($DomainLocalDistributionGroups / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Domain Local Distribution Groups'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $DomainLocalDistributionGroups
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Domain Local Distribution Groups' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($UniversalDistributionGroups / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Universal Distribution Groups'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $UniversalDistributionGroups
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Universal Distribution Groups' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($GlobalSecurityGroups / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Global Security Groups'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $GlobalSecurityGroups
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Global Security Groups' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($DomainLocalSecurityGroups / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Domain Local Security Groups'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $DomainLocalSecurityGroups
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Domain Local Security Groups' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($BuiltinLocalSecurityGroups / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Builtin Local Security Groups'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $BuiltinLocalSecurityGroups
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Builtin Local Security Groups' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($UniversalSecurityGroups / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Universal Security Groups'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $UniversalSecurityGroups
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Universal Security Groups' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($UnrecognisedGroupTypes / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Unrecognised Group Type'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $UnrecognisedGroupTypes
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Unrecognised Group Type' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalNoMembers / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups with no members'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalNoMembers
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups with no members' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalMailEnabledObjects / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups that are mail-enabled'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalMailEnabledObjects
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups that are mail-enabled' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalUnixEnabledObjects / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups that are Unix-enabled'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalUnixEnabledObjects
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups that are Unix-enabled' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $TotalDistributionGroups = $GlobalDistributionGroups + $DomainLocalDistributionGroups + $UniversalDistributionGroups
    $percent = '{0:P}' -f (($TotalDistributionGroups - $TotalMailEnabledDistributionGroups) / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Distribution Groups that are mail-disabled'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value ($TotalDistributionGroups - $TotalMailEnabledDistributionGroups)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Distribution Groups that are mail-disabled' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalCriticalSystemObjects / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups that are critical system objects'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalCriticalSystemObjects
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups that are critical system objects' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalProtectedObjects / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups that are protected objects (AdminSDHolder)'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalProtectedObjects
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups that are protected objects (AdminSDHolder)' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalExcludedObjects / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups that are marked as excluded objects'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalExcludedObjects
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups that are marked as excluded objects' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalExpiredObjects / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups that have expired'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalExpiredObjects
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups that have expired' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f (($TotalNoMembers - $TotalToSubtract) / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups with no members that are not critical system, protected, or excluded objects'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value ($TotalNoMembers - $TotalToSubtract)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups with no members that are not critical system, protected, or excluded objects' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalConflictingObjects / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups that are conflicting/duplicate objects'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalConflictingObjects
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups that are conflicting/duplicate objects' = $Summaryobj }
    $Summaryobj = $Null

    $Summaryobj = New-Object -TypeName PSObject
    $percent = '{0:P}' -f ($TotalWithSIDHistory / $GroupCount)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Item' -Value ($Item = $Item + 1)
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Statement' -Value 'Groups with SID history'
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Total_Count' -Value $TotalWithSIDHistory
    $Summaryobj | Add-Member -MemberType NoteProperty -Name 'Overall_Percentage' -Value $percent
    $SummaryHashTable = $SummaryHashTable + @{'Groups with SID history' = $Summaryobj }
    $Summaryobj = $Null

    Write-Host -ForegroundColor Green 'Summary Totals:'

    $Output = $SummaryHashTable.values | ForEach-Object { $_ } | ForEach-Object { $_ } | Sort-Object Item
    $Output | Format-Table -AutoSize

    # Write-Output $Output | Format-Table
    $Output | Export-Csv -Path "$ReferenceFileSummaryTotals" -Delimiter $Delimiter -NoTypeInformation

    # Remove the quotes
    If ($RemoveQuotesFromCSV) {
    (Get-Content "$ReferenceFileSummaryTotals") | ForEach-Object { $_ -replace '"', '' } | Out-File "$ReferenceFileSummaryTotals" -Fo -En ascii
    }

    Write-Host 'Notes:' -ForegroundColor Yellow
    Write-Host ' - Disabling groups:' -ForegroundColor Yellow
    Write-Host '   - Security groups can be disabled by converting them to a distribution group.' -ForegroundColor Yellow
    Write-Host '   - Distribution groups can be disabled by mail-disabling them.' -ForegroundColor Yellow
    Write-Host "   You should always clearly document situations where groups have been disabled. i.e.`n   Are they being kept for a reason, or should they be deleted. Delete them if they no`n   longer serve a purpose." -ForegroundColor Yellow
    Write-Host ' - You should never delete groups marked as Critical System Objects.' -ForegroundColor Yellow
    Write-Host " - Some groups may simply be placeholders for certain tasks, scripts and policies, and`n   therefore may purposely not contain any members. Simply move these groups into an OU and`n   add the OU to the `$ExclusionOUs array to flag and exclude them from the final no members`n   count when this script is re-run." -ForegroundColor Yellow
    Write-Host " - In general add groups and OUs to the 'Exclusion' arrays to flag and exclude groups`n   with no members from the final no members count." -ForegroundColor Yellow
    Write-Host " - Review the value of groups that contain no members, are not critical system objects,`n   protected objects (AdminSDHolder), and not excluded objects. Delete them if they are no`n   longer serving their purpose. Alternatively, move them into an OU and add the OU to the`n   `$ExclusionOUs array." -ForegroundColor Yellow
    Write-Host " - Review the groups that have been marked as protected objects (AdminSDHolder) that may`n   now fall out of scope. If these groups are not going to be deleted, they should be`n   restored to their original state  by reactivating the inheritance rights on the object`n   itself and clearing the adminCount attribute." -ForegroundColor Yellow
    Write-Host " - There should be no groups with an unrecognised group type. But if there are any, they`n   must be investigated and remediated immediately as they could be the result of more`n   serious issues." -ForegroundColor Yellow
    Write-Host " - Groups whose name contains CNF: and/or sAMAccountName contains `$Duplicate means that`n   it's a duplicate account caused by conflicting/duplicate objects. This typically occurs`n   when objects are created on different Read Write Domain Controllers at nearly the same`n   time. After replication kicks in and those conflicting/duplicate objects replicate to`n   other Read Write Domain Controllers, Active Directory replication applies a conflict`n   resolution mechanism to ensure every object is and remains unique. You can't just delete`n   the conflicting/duplicate objects, as these may often be in use. You need to merge the`n   group membership and ensure the valid group is correctly applied to the resource. Then`n   you can confidently delete the conflicting/duplicate group." -ForegroundColor Yellow
    Write-Host " - A nice way to manage groups is to set their expirationTime attribute. This will give`n   us the ability to implement a nice lifecycle management process. You can go one step`n   further and add a user or mail enabled security group to the managedBy attribute. This`n   will give us the ability to implement some workflow when the group is x days before`n   expiring." -ForegroundColor Yellow

    Write-Host "`nCSV files to review:" -ForegroundColor Yellow
    Write-Host " - $ReferenceFileFull" -ForegroundColor Yellow
    Write-Host " - $ReferenceFileSummary" -ForegroundColor Yellow
    Write-Host " - $ReferenceFileSummaryTotals" -ForegroundColor Yellow

}
