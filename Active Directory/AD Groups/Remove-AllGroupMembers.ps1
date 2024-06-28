#Created by the Scripting Guy
#http://blogs.technet.com/b/heyscriptingguy/archive/2009/07/28/hey-scripting-guy-how-do-i-remove-all-group-members-in-active-directory.aspx

Param(
   [string]$group,
   [string]$ou,
   [string]$domain,
   [switch]$whatif,
   [switch]$help
) #end param

Function Get-ScriptHelp
{
 "Remove-AllGroupMembers.ps1 removes all members of a group"
 "Remove-AllGroupMembers.ps1 -group cn=mygroup -ou ou=myou -domain 'dc=nwtraders,dc=com'"
 "Remove-AllGroupMembers.ps1 -group cn=mygroup -ou ou=myou -domain 'dc=nwtraders,dc=com' -whatif"
} # end function Get-ScriptHelp

Function Remove-AllGroupMembers
{
 Param(
   [string]$group,
   [string]$ou,
   [string]$domain
 ) #end param
 $ads_Property_Clear = 1
 $de = [adsi]"LDAP://$group,$ou,$domain"
 $de.putex($ads_Property_Clear,"member",$null)
 $de.SetInfo()
} # end function Remove-AllGroupMembers

Function Get-Whatif
{
  Param(
   [string]$group,
   [string]$ou,
   [string]$domain
 ) #end param
 "WHATIF: Remove all members from $group,$ou,$domain" 
} #end function Get-Whatif

# *** Entry Point to script ***

if(-not($group -and $ou -and $domain)) 
  { throw ("group ou and domain required") }
if($whatif) { Get-Whatif -group $group -ou $ou -domain $domain ; exit }
if($help) { Get-Scripthelp ; exit }
"Removing all members from $group,$ou,$domain"
Remove-AllGroupMembers -group $group -ou $ou -domain $domain