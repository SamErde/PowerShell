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
param([String]$TrustedDomain,[switch]$verbose)

Set-StrictMode -Version 2.0

if ($verbose.IsPresent) { 
  $VerbosePreference = 'Continue' 
  Write-Verbose "Verbose Mode Enabled" 
} 
Else { 
  $VerbosePreference = 'SilentlyContinue' 
}

#-------------------------------------------------------------

# Set this to the OU structure where the you want to search to
# start from. Do not add the Domain DN. If you leave it blank,
# the script will start from the root of the domain.
$OUStructureToProcess = ""

# Set the name of the attribute you want to populate for objects
# to be evaluated as a stale or non-stale object.
$ExcludeAttribute = "comment"

# Set the text within the $ExcludeAttribute that you want to use
# to evaluate if the object should be excluded from the stale
# object collection.
$ExcludeText = "Decommission=False"

# Set this to the delimiter for the CSV output
$Delimiter = ","

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
"DnsAdmins",`
"DnsUpdateProxy",`
"DHCP Users",`
"DHCP Administrators",`
"Offer Remote Assistance Helpers",`
"TelnetClients",`
"IIS_WPG",`
"Access Control Assistance Operators",`
"Cloneable Domain Controllers",`
"Hyper-V Administrators",`
"Protected Users",`
"RDS Endpoint Servers",`
"RDS Management Servers",`
"RDS Remote Access Servers",`
"Remote Management Users",`
"WinRMRemoteWMIUsers_",`
"RTC*"
)

$ExclusionOUs = @(
"*Microsoft Exchange System Objects*"
"*Microsoft Exchange Security Groups*"
)

#-------------------------------------------------------------

$invalidChars = [io.path]::GetInvalidFileNamechars() 
$datestampforfilename = ((Get-Date -format s).ToString() -replace "[$invalidChars]","-")

# Get the script path
$ScriptPath = {Split-Path $MyInvocation.ScriptName}
$ReferenceFileFull = $(&$ScriptPath) + "\GroupReport-Full-$($datestampforfilename).csv"
$ReferenceFileSummary = $(&$ScriptPath) + "\GroupReport-Summary-$($datestampforfilename).csv"
$ReferenceFileSummaryTotals = $(&$ScriptPath) + "\GroupReport-Summary-Totals-$($datestampforfilename).csv"

if (Test-Path -path $ReferenceFileFull) {
  remove-item $ReferenceFileFull -force -confirm:$false
}
if (Test-Path -path $ReferenceFileSummary) {
  remove-item $ReferenceFileSummary -force -confirm:$false
}
if (Test-Path -path $ReferenceFileSummaryTotals) {
  remove-item $ReferenceFileSummaryTotals -force -confirm:$false
}

if ([String]::IsNullOrEmpty($TrustedDomain)) {
  # Get the Current Domain Information
  $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
} else {
  $context = new-object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$TrustedDomain)
  Try {
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($context)
  }
  Catch [exception] {
    write-host -ForegroundColor red $_.Exception.Message
    Exit
  }
}

# Get AD Distinguished Name
$DomainDistinguishedName = $Domain.GetDirectoryEntry() | select -ExpandProperty DistinguishedName  

If ($OUStructureToProcess -eq "") {
  $ADSearchBase = $DomainDistinguishedName
} else {
  $ADSearchBase = $OUStructureToProcess + "," + $DomainDistinguishedName
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
$ADFilter = "(objectClass=group)"

# There is a known bug in PowerShell requiring the DirectorySearcher
# properties to be in lower case for reliability.
$ADPropertyList = @("name","distinguishedname","samaccountname","mail","grouptype", `
                    "displayname","description","member","memberof","info", `
                    "isCriticalSystemObject","admincount","managedBy","objectsid", `
                    "expirationtime","whencreated","whenchanged","sidhistory", `
                    "proxyaddresses","legacyexchangedn","mailnickname", `
                    "reporttooriginator","gidnumber","mssfu30name","mssfu30nisdomain")
$ADScope = "SUBTREE"
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
  write-host -ForegroundColor Green "`nPlease be patient whilst the script retrieves all group objects and specified attributes..."
  $colResults = $ADSearcher.Findall()
  # Dispose of the search and results properly to avoid a memory leak
  $ADSearcher.Dispose()
  $GroupCount = $colResults.Count
}
Catch {
  $GroupCount = 0
  Write-Host -ForegroundColor red "The $ADSearchBase structure cannot be found!"
}
if ($GroupCount -ne 0) {

  write-host -ForegroundColor Green "`nProcessing $GroupCount group objects in the $domain Domain..."

  $colResults | ForEach-Object {
    $group = $_.GetDirectoryEntry()             

    $Name = $($group.Name)
    $ParentOU = $($group.DistinguishedName)  -split '(?<![\\]),'
    $ParentOU = $ParentOU[1..$($ParentOU.Count-1)] -join ','

    switch($($group.GroupType)){            
      2  {            
           $GroupCategory = "Distribution"            
           $GroupScope = "Global"
           $GlobalDistributionGroups = $GlobalDistributionGroups + 1
           Break
         }            
      4  {            
           $GroupCategory = "Distribution"            
           $GroupScope = "Domain Local"            
           $DomainLocalDistributionGroups = $DomainLocalDistributionGroups + 1
           Break
         }             
      8  {            
           $GroupCategory = "Distribution"            
           $GroupScope = "Universal"            
           $UniversalDistributionGroups = $UniversalDistributionGroups + 1
           Break
         }             
      -2147483646  {            
           $GroupCategory = "Security"            
           $GroupScope = "Global"            
           $GlobalSecurityGroups = $GlobalSecurityGroups + 1
           Break
         }            
      -2147483644  {            
           $GroupCategory = "Security"            
           $GroupScope = "Domain Local"            
           $DomainLocalSecurityGroups = $DomainLocalSecurityGroups + 1
           Break
         }            
      -2147483643   {            
           $GroupCategory = "Security"            
           $GroupScope = "Builtin Local"            
           $BuiltinLocalSecurityGroups = $BuiltinLocalSecurityGroups + 1
           Break
         }            
      -2147483640  {            
           $GroupCategory = "Security"            
           $GroupScope = "Universal"            
           $UniversalSecurityGroups = $UniversalSecurityGroups + 1
           Break
         }             
      default {
           $GroupCategory = "Unrecognised"            
           $GroupScope = "Unrecognised"            
           $UnrecognisedGroupTypes = $UnrecognisedGroupTypes + 1
         }             

    }

    $MemberCount = 0
    If (($group.Member | Measure-Object).Count -gt 0) {
        $group.Member | ForEach-Object {
        $MemberCount = $MemberCount + 1
      }
    }
    If ($MemberCount -eq 0) {$TotalNoMembers = $TotalNoMembers + 1}

    $MailEnabled = $False
    If (($group.proxyaddresses | Measure-Object).Count -gt 0 -AND
        ($group.legacyexchangedn | Measure-Object).Count -gt 0 -AND
        ($group.mailnickname | Measure-Object).Count -gt 0 -AND
        $group.reporttooriginator -eq $True) {
      $MailEnabled = $True
      $TotalMailEnabledObjects = $TotalMailEnabledObjects + 1
      If ($GroupCategory -eq "Distribution") {
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

    If ($group.isCriticalSystemObject -eq $True) {$TotalCriticalSystemObjects = $TotalCriticalSystemObjects + 1}

    If (($group.adminCount| Measure-Object).Count -gt 0) {
      # Use the bitwise-AND (-bAnd) operator to determine if the least significant bit is set (1) or clear (0)
      $AdminCount = ($($group.adminCount) -band 00000001)
      If ($AdminCount -eq "1") {$TotalProtectedObjects = $TotalProtectedObjects + 1}
    } Else {
      $AdminCount = ""
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
    If ($Exclude) {$TotalExcludedObjects = $TotalExcludedObjects + 1}

    $Conflict = $False
    If ($Name -Like "*CNF:*" -OR $group.sAMAccountName -Like "`$Duplicate*") {
      # Replace the Line Feed character in the name so that it's a nicely represented string.
      $Name = $Name -replace "`n",""
      $Conflict = $True
      $TotalConflictingObjects = $TotalConflictingObjects + 1
    }

    If ($MemberCount -eq 0 -AND ($group.isCriticalSystemObject -eq $True -OR $AdminCount -eq "1" -OR $Exclude)) {$TotalToSubtract = $TotalToSubtract + 1}

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
      $notes = $notes -replace "`r`n", "|"
    } else {
      $notes = ""
    }

    # Get SID
    $stringSID = (New-Object System.Security.Principal.SecurityIdentifier($group.objectsid[0],0)).Value

    $FullGroupType = "$GroupScope $GroupCategory Group"
    $obj = New-Object -TypeName PSObject
    $obj | Add-Member -MemberType NoteProperty -Name "GroupType" -value $FullGroupType

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
      If ($MemberCount -eq 0) {$NoMembersCount = 1}
      If ($MailEnabled) {
        $MailEnabledCount = 1
      } Else {
        $MailDisabledCount = 1
      }
      If ($UnixEnabled) {
        $UnixEnabledCount = 1
      }
      If ($group.isCriticalSystemObject -eq $True) {$CriticalSystemObjectCount = 1}
      If ($AdminCount -eq "1") {$ProtectedObjectCount = 1}
      If ($Exclude) {$ExcludeObjectCount = 1}
      If ($Expired) {$ExpiredObjectCount = 1}
      If ($Conflict) {$ConflictCount = 1}
      If ($SIDHistoryCount -ne 0) {$ContainSIDHistoryCount = 1}
      $obj | Add-Member -MemberType NoteProperty -Name "Total" -value $TotalCount
      $obj | Add-Member -MemberType NoteProperty -Name "No_Members" -value $NoMembersCount
      $obj | Add-Member -MemberType NoteProperty -Name "Mail_Enabled" -value $MailEnabledCount
      $obj | Add-Member -MemberType NoteProperty -Name "Mail_Disabled" -value $MailDisabledCount
      $obj | Add-Member -MemberType NoteProperty -Name "Unix_Enabled" -value $UnixEnabledCount
      $obj | Add-Member -MemberType NoteProperty -Name "Critical_System" -value $CriticalSystemObjectCount
      $obj | Add-Member -MemberType NoteProperty -Name "Protected" -value $ProtectedObjectCount
      $obj | Add-Member -MemberType NoteProperty -Name "Conflicting" -value $ConflictCount
      $obj | Add-Member -MemberType NoteProperty -Name "SIDHistory" -value $ContainSIDHistoryCount
      $obj | Add-Member -MemberType NoteProperty -Name "Expired" -value $ExpiredObjectCount
      $obj | Add-Member -MemberType NoteProperty -Name "Excluded" -value $ExcludeObjectCount
      $GroupsHashTable = $GroupsHashTable + @{$FullGroupType = $obj}
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
      If ($MemberCount -eq 0) {$NoMembersCount = $NoMembersCount + 1}
      If ($MailEnabled) {
        $MailEnabledCount = $MailEnabledCount + 1
      } Else {
        $MailDisabledCount = $MailDisabledCount + 1
      }
      If ($UnixEnabled) {
        $UnixEnabledCount = $UnixEnabledCount + 1
      }
      If ($group.isCriticalSystemObject -eq $True) {$CriticalSystemObjectCount = $CriticalSystemObjectCount + 1}
      If ($AdminCount -eq "1") {$ProtectedObjectCount = $ProtectedObjectCount + 1}
      If ($Exclude) {$ExcludeObjectCount = $ExcludeObjectCount + 1}
      If ($Expired) {$ExpiredObjectCount = $ExpiredObjectCount + 1}
      If ($Conflict) {$ConflictCount = $ConflictCount + 1}
      If ($SIDHistoryCount -ne 0) {$ContainSIDHistoryCount = $ContainSIDHistoryCount + 1}
      $obj | Add-Member -MemberType NoteProperty -Name "Total" -value $TotalCount
      $obj | Add-Member -MemberType NoteProperty -Name "No_Members" -value $NoMembersCount
      $obj | Add-Member -MemberType NoteProperty -Name "Mail_Enabled" -value $MailEnabledCount
      $obj | Add-Member -MemberType NoteProperty -Name "Mail_Disabled" -value $MailDisabledCount
      $obj | Add-Member -MemberType NoteProperty -Name "Unix_Enabled" -value $UnixEnabledCount
      $obj | Add-Member -MemberType NoteProperty -Name "Critical_System" -value $CriticalSystemObjectCount
      $obj | Add-Member -MemberType NoteProperty -Name "Protected" -value $ProtectedObjectCount
      $obj | Add-Member -MemberType NoteProperty -Name "Conflicting" -value $ConflictCount
      $obj | Add-Member -MemberType NoteProperty -Name "SIDHistory" -value $ContainSIDHistoryCount
      $obj | Add-Member -MemberType NoteProperty -Name "Expired" -value $ExpiredObjectCount
      $obj | Add-Member -MemberType NoteProperty -Name "Excluded" -value $ExcludeObjectCount
      $GroupsHashTable.Set_Item($FullGroupType,$obj)
    }
    $obj = $Null

    $obj = New-Object -TypeName PSObject
    $obj | Add-Member -MemberType NoteProperty -Name "Name" -value $Name 
    $obj | Add-Member -MemberType NoteProperty -Name "ParentOU" -value $ParentOU
    $obj | Add-Member -MemberType NoteProperty -Name "sAMAccountName" -value $($group.sAMAccountName) 
    $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -value $($group.displayname) 
    $obj | Add-Member -MemberType NoteProperty -Name "Description" -value $($group.description) 
    $obj | Add-Member -MemberType NoteProperty -Name "MemberCount" -value $MemberCount
    $obj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -value $GroupCategory
    $obj | Add-Member -MemberType NoteProperty -Name "GroupScope" -value $GroupScope
    $obj | Add-Member -MemberType NoteProperty -Name "Mail" -value $($group.mail)
    $obj | Add-Member -MemberType NoteProperty -Name "MailEnabled" -value $MailEnabled
    $obj | Add-Member -MemberType NoteProperty -Name "isCriticalSystemObject" -value $($group.isCriticalSystemObject) 
    $obj | Add-Member -MemberType NoteProperty -Name "AdminCount" -value $($group.adminCount) 
    $obj | Add-Member -MemberType NoteProperty -Name "Exclude" -value $Exclude
    $obj | Add-Member -MemberType NoteProperty -Name "Expired" -value $Expired
    $obj | Add-Member -MemberType NoteProperty -Name "Conflicting" -value $Conflict
    $obj | Add-Member -MemberType NoteProperty -Name "managedBy" -value $($group.managedBy)
    $obj | Add-Member -MemberType NoteProperty -Name "ExpirationTime" -value $ExpirationTime
    $obj | Add-Member -MemberType NoteProperty -Name "WhenChanged" -value $WhenChanged
    $obj | Add-Member -MemberType NoteProperty -Name "WhenCreated" -value $WhenCreated
    $obj | Add-Member -MemberType NoteProperty -Name "SIDHistoryCount" -value $SIDHistoryCount
    $obj | Add-Member -MemberType NoteProperty -Name "UnixEnabled" -value $UnixEnabled
    $obj | Add-Member -MemberType NoteProperty -Name "GIDNumber" -value $($group.gidnumber)
    $obj | Add-Member -MemberType NoteProperty -Name "info" -value $notes
    $obj | Add-Member -MemberType NoteProperty -Name "objectsid" -value $stringSID

    # PowerShell V2 doesn't have an Append parameter for the Export-Csv cmdlet. Out-File does, but it's
    # very difficult to get the formatting right, especially if you want to use quotes around each item
    # and add a delimeter. However, we can easily do this by piping the object using the ConvertTo-Csv,
    # Select-Object and Out-File cmdlets instead.
    if ($PSVersionTable.PSVersion.Major -gt 2) {
      $obj | Export-Csv -Path "$ReferenceFileFull" -Append -Delimiter $Delimiter -NoTypeInformation -Encoding ASCII
    } Else {
      if (!(Test-Path -path $ReferenceFileFull)) {
        $obj | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -First 1 | Out-File -Encoding ascii -filepath "$ReferenceFileFull"
      }
      $obj | ConvertTo-Csv -NoTypeInformation -Delimiter $Delimiter | Select-Object -Skip 1 | Out-File -Encoding ascii -filepath "$ReferenceFileFull" -append -noclobber
    }
    $obj = $Null

    $TotalGroupsProcessed ++
    If ($ProgressBar) {
      Write-Progress -Activity 'Processing Groups' -Status ("Name: {0}" -f $Name) -PercentComplete (($TotalGroupsProcessed/$GroupCount)*100)
    }

  }

  # Dispose of the search and results properly to avoid a memory leak
  $colResults.Dispose()

  # Remove the quotes from the output file.
  If ($RemoveQuotesFromCSV) {
    (get-content "$ReferenceFileFull") |% {$_ -replace '"',""} | out-file "$ReferenceFileFull" -Fo -En ascii
  }

  write-host -ForegroundColor Green "`nA breakdown of the $GroupCount Group Objects in the $domain Domain:"

  $Output = $GroupsHashTable.values | ForEach {$_ } | ForEach {$_ } | Sort-Object GroupType -descending
  # Auto-sized tables are by default limited to the width of your screen buffer. So to
  # ensure all columns of the table are displayed we force it to 4096 characters. I also
  # find that the Format-Table cmdlet will output a maximum of 10 columns by default, so
  # you must use the "Property" parameter and set it to *.
  $Output | Format-Table -Property * -AutoSize | Out-String -Width 4096

  # Write-Output $Output | Format-Table
  $Output | Export-Csv -Path "$ReferenceFileSummary" -Delimiter $Delimiter -NoTypeInformation

  # Remove the quotes
  If ($RemoveQuotesFromCSV) {
    (get-content "$ReferenceFileSummary") |% {$_ -replace '"',""} | out-file "$ReferenceFileSummary" -Fo -En ascii
  }

  # Note that for the summary output I went with a hashtable instead of binding multiple objects together.
  # Whilst some of the code may seem excessive and repetitive, I found this the simplest method to achieve
  # the desired output.
  $SummaryHashTable = @{}
  $Item = 0

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($GlobalDistributionGroups/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Global Distribution Groups"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $GlobalDistributionGroups
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Global Distribution Groups" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($DomainLocalDistributionGroups/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Domain Local Distribution Groups"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $DomainLocalDistributionGroups
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Domain Local Distribution Groups" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($UniversalDistributionGroups/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Universal Distribution Groups"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $UniversalDistributionGroups
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Universal Distribution Groups" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($GlobalSecurityGroups/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Global Security Groups"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $GlobalSecurityGroups
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Global Security Groups" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($DomainLocalSecurityGroups/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Domain Local Security Groups"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $DomainLocalSecurityGroups
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Domain Local Security Groups" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($BuiltinLocalSecurityGroups/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Builtin Local Security Groups"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $BuiltinLocalSecurityGroups
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Builtin Local Security Groups" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($UniversalSecurityGroups/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Universal Security Groups"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $UniversalSecurityGroups
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Universal Security Groups" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($UnrecognisedGroupTypes/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Unrecognised Group Type"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $UnrecognisedGroupTypes
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Unrecognised Group Type" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalNoMembers/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups with no members" 
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalNoMembers
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups with no members" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalMailEnabledObjects/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups that are mail-enabled"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalMailEnabledObjects
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups that are mail-enabled" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalUnixEnabledObjects/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups that are Unix-enabled"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalUnixEnabledObjects
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups that are Unix-enabled" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $TotalDistributionGroups = $GlobalDistributionGroups + $DomainLocalDistributionGroups + $UniversalDistributionGroups
  $percent = "{0:P}" -f (($TotalDistributionGroups - $TotalMailEnabledDistributionGroups)/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Distribution Groups that are mail-disabled"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value ($TotalDistributionGroups - $TotalMailEnabledDistributionGroups)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Distribution Groups that are mail-disabled" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalCriticalSystemObjects/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups that are critical system objects"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalCriticalSystemObjects
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups that are critical system objects" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalProtectedObjects/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups that are protected objects (AdminSDHolder)"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalProtectedObjects
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups that are protected objects (AdminSDHolder)" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalExcludedObjects/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups that are marked as excluded objects"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalExcludedObjects
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups that are marked as excluded objects" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalExpiredObjects/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups that have expired"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalExpiredObjects
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups that have expired" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f (($TotalNoMembers - $TotalToSubtract)/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups with no members that are not critical system, protected, or excluded objects"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value ($TotalNoMembers - $TotalToSubtract)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups with no members that are not critical system, protected, or excluded objects" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalConflictingObjects/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups that are conflicting/duplicate objects"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalConflictingObjects
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups that are conflicting/duplicate objects" = $Summaryobj}
  $Summaryobj = $Null

  $Summaryobj = New-Object -TypeName PSObject
  $percent = "{0:P}" -f ($TotalWithSIDHistory/$GroupCount)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Item" -value ($Item = $Item + 1)
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Statement" -value "Groups with SID history"
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Total_Count" -value $TotalWithSIDHistory
  $Summaryobj | Add-Member -MemberType NoteProperty -Name "Overall_Percentage" -value $percent
  $SummaryHashTable = $SummaryHashTable + @{"Groups with SID history" = $Summaryobj}
  $Summaryobj = $Null

  write-host -ForegroundColor Green "Summary Totals:"

  $Output = $SummaryHashTable.values | ForEach {$_ } | ForEach {$_ } | Sort-Object Item
  $Output | Format-Table -AutoSize

  # Write-Output $Output | Format-Table
  $Output | Export-Csv -Path "$ReferenceFileSummaryTotals" -Delimiter $Delimiter -NoTypeInformation

  # Remove the quotes
  If ($RemoveQuotesFromCSV) {
    (get-content "$ReferenceFileSummaryTotals") |% {$_ -replace '"',""} | out-file "$ReferenceFileSummaryTotals" -Fo -En ascii
  }

  write-host "Notes:" -foregroundColor Yellow
  write-host " - Disabling groups:" -foregroundColor Yellow
  write-host "   - Security groups can be disabled by converting them to a distribution group." -foregroundColor Yellow
  write-host "   - Distribution groups can be disabled by mail-disabling them." -foregroundColor Yellow
  write-host "   You should always clearly document situations where groups have been disabled. i.e.`n   Are they being kept for a reason, or should they be deleted. Delete them if they no`n   longer serve a purpose." -foregroundColor Yellow
  write-host " - You should never delete groups marked as Critical System Objects." -foregroundColor Yellow
  write-host " - Some groups may simply be placeholders for certain tasks, scripts and policies, and`n   therefore may purposely not contain any members. Simply move these groups into an OU and`n   add the OU to the `$ExclusionOUs array to flag and exclude them from the final no members`n   count when this script is re-run." -foregroundColor Yellow
  write-host " - In general add groups and OUs to the 'Exclusion' arrays to flag and exclude groups`n   with no members from the final no members count." -foregroundColor Yellow
  write-host " - Review the value of groups that contain no members, are not critical system objects,`n   protected objects (AdminSDHolder), and not excluded objects. Delete them if they are no`n   longer serving their purpose. Alternatively, move them into an OU and add the OU to the`n   `$ExclusionOUs array." -foregroundColor Yellow
  write-host " - Review the groups that have been marked as protected objects (AdminSDHolder) that may`n   now fall out of scope. If these groups are not going to be deleted, they should be`n   restored to their original state  by reactivating the inheritance rights on the object`n   itself and clearing the adminCount attribute." -foregroundColor Yellow
  write-host " - There should be no groups with an unrecognised group type. But if there are any, they`n   must be investigated and remediated immediately as they could be the result of more`n   serious issues." -foregroundColor Yellow
  write-host " - Groups whose name contains CNF: and/or sAMAccountName contains `$Duplicate means that`n   it's a duplicate account caused by conflicting/duplicate objects. This typically occurs`n   when objects are created on different Read Write Domain Controllers at nearly the same`n   time. After replication kicks in and those conflicting/duplicate objects replicate to`n   other Read Write Domain Controllers, Active Directory replication applies a conflict`n   resolution mechanism to ensure every object is and remains unique. You can't just delete`n   the conflicting/duplicate objects, as these may often be in use. You need to merge the`n   group membership and ensure the valid group is correctly applied to the resource. Then`n   you can confidently delete the conflicting/duplicate group." -foregroundColor Yellow
  write-host " - A nice way to manage groups is to set their expirationTime attribute. This will give`n   us the ability to implement a nice lifecycle management process. You can go one step`n   further and add a user or mail enabled security group to the managedBy attribute. This`n   will give us the ability to implement some workflow when the group is x days before`n   expiring." -foregroundColor Yellow

  write-host "`nCSV files to review:" -foregroundColor Yellow
  write-host " - $ReferenceFileFull" -foregroundColor Yellow
  write-host " - $ReferenceFileSummary" -foregroundColor Yellow
  write-host " - $ReferenceFileSummaryTotals" -foregroundColor Yellow

}
