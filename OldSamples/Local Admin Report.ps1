#$Servers = Get-ADComputer -Server DOMAINNAME.org -SearchBase "OU=Member Servers,DC=DOMAINNAME,DC=org" -Filter * -Properties OperatingSystem | Where OperatingSystem -Match "Windows"

$Computer = ' '

<#
$ADSIComputer = [ADSI]("WinNT://$Computer,computer")
$group = $ADSIComputer.psbase.children.find('Administrators',  'Group')
$group.psbase.invoke("members")  | ForEach{ $_.GetType().InvokeMember("Name",  'GetProperty',  $null,  $_, $null) }

Write-Host "=============================================================================="


$admins = Get-WmiObject -Class Win32_GroupUser -Computer $Computer   
$admins = $admins | Where-Object {$_.groupcomponent -like '*"Administrators"'}  
$admins = $admins | ForEach-Object {  
    $_.partcomponent -match ".+Domain\=(.+)\,Name\=(.+)$"" > $nul  
    $matches[1].trim('"') + "\" + $matches[2].trim('"')  
}#>


        $admins = Get-CimInstance -ClassName Win32_GroupUser -Computer $Computer | Where-Object {$_.groupcomponent -like '*"Administrators"'} | ForEach-Object {  
            $_.partcomponent -match ".+Domain\=(.+)\,Name\=(.+)$" > $nul  
            $matches[1].trim('"') + "\" + $matches[2].trim('"')  
        }

$admins

  $group = Get-CimInstance -ClassName Win32_Group -Computer $Computer -Filter "LocalAccount=True AND SID='S-1-5-32-544'"
  $list = Get-CimInstance -ClassName Win32_GroupUser -ComputerName $Computer -Filter "GroupComponent = `"Win32_Group.Domain='$($group.domain)'`,Name='$($group.name)'`""
  $list.PartComponent | ForEach-Object {$_.substring($_.lastindexof("Domain=") + 7).replace("`",Name=`"","\")}

  $list = Get-CimInstance -ClassName Win32_GroupUser -ComputerName $Computer -Filter "GroupComponent LIKE '%Administrators'"
  $list.PartComponent | ForEach-Object {$_.substring($_.lastindexof("Domain=") + 7).replace("`",Name=`"","\")}


  Get-Get-CimInstance -ClassName win32_group -filter "LocalAccount=True AND SID='S-1-5-32-544'" -computername $Computer | 
  Select-Object PSComputername,Name,@{Name="Members";Expression={$_.GetRelated("win32_account").Name -join ";" }}

$wmiObject = Get-CimInstance -ClassName Win32_Group -Filter "LocalAccount=TRUE and SID='S-1-5-32-544'" #-ComputerName $Computer 
$wmiObject.GetRelated("Win32_Account","Win32_GroupUser","","","PartComponent","GroupComponent",$FALSE,$NULL).Caption

$wmiObject = Invoke-Command -Credential (get-credential) -ComputerName $Computer -ScriptBlock {(Get-CimInstance -ClassName Win32_Group -Filter "LocalAccount=TRUE and SID='S-1-5-32-544'").GetRelated("Win32_Account","Win32_GroupUser","","","PartComponent","GroupComponent",$FALSE,$NULL).Caption}


function get-localadmins{
  [cmdletbinding()]
  Param(
  [string]$computerName
  )
  $group = Get-CimInstance -ClassName win32_group -ComputerName $computerName -Filter "LocalAccount=True AND SID='S-1-5-32-544'"
  $query = "GroupComponent = `"Win32_Group.Domain='$($group.domain)'`,Name='$($group.name)'`""
  $list = Get-CimInstance -ClassName win32_groupuser -ComputerName $computerName -Filter $query
  $list.PartComponent | ForEach-Object {$_.substring($_.lastindexof("Domain=") + 7).replace("`",Name=`"","\")}
}

get-localadmins ComputerName
