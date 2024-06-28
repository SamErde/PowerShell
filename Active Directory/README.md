# PowerShell Scripts and Tools for Active Directory

This repository is a collection of scripts for working with Active Directory. Some of them are recently built and
maintained; others are old, purpose-built scripts that I kept for historical purposes; and a few of these may be
scripts that I have found on the web over the years and didn't want to loose track of.

I will try to keep track of actively maintained scripts below:

## Get-ADUserEncryptionTypes

[Get-ADUserEncryptionTypes.ps1](./Get-ADUserEncryptionTypes.ps1): A tool to help track user encryption types in Active Directory and work towards using AES instead of less secure types like RC4 and DES.

## Get-GPOsMissingPermissions

[Get-GPOsMissingPermissions.ps1](./Get-GPOsMissingPermissions.ps1): A tool to help find GPOs that are missing permissions for either Authenticated Users or Domain Computers.

## Get-OrganizationalUnitDepth

[Get-OrganizationalUnitDepth.ps1](./Get-OrganizationalUnitDepth.ps1): A tool to report the deepest levels of OUs in your Active Directory hierarchy so you can audit and plan for a simpler structure.

## Test-IsMemberOfProtectedUsers

[Test-IsMemberOfProtectedUsers](./Test-IsMemberOfProtectedUsers.ps1): A tool to check if a user is a member of the Protected Users group in Active Directory.
