# Snippets to activate Windows and get the license key
# Found from internet. Need to review and cleanup.

# Activate Windows
$ProductKey = (Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey
if ([string]::IsNullOrWhiteSpace($ProductKey)) {
    throw 'No OEM product key was found in SoftwareLicensingService.OA3xOriginalProductKey.'
}

if ($ProductKey -notmatch '^[A-Z0-9]{5}(-[A-Z0-9]{5}){4}$') {
    throw 'The product key returned by SoftwareLicensingService.OA3xOriginalProductKey is not in the expected format.'
}

& "$env:SystemRoot\System32\cscript.exe" '/b' "$env:SystemRoot\System32\slmgr.vbs" '-ipk' $ProductKey
Start-Sleep 5
& "$env:SystemRoot\System32\cscript.exe" '/b' "$env:SystemRoot\System32\slmgr.vbs" '-ato'



# Define the registry key path and value
$registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MfaRequiredInClipRenew'
$registryValueName = 'Verify Multi-factor Authentication in ClipRenew'
$registryValueData = 0  # DWORD value of 0
$sid = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-4')
# SID for the Everyone group
# or SID S-1-5-4 for the interactive group

# Check if the registry key already exists
if (-not (Test-Path -Path $registryPath)) {
    # If the key doesn't exist, create it and set the DWORD value
    New-Item -Path $registryPath -Force | Out-Null
    Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $registryValueData -Type DWORD
    Write-Output 'Registry key created and DWORD value added.'
} else {
    Write-Output 'Registry key already exists. No changes made.'
}

# Add read permissions for SID (S-1-1-0, Everyone) to the registry key with inheritance
$acl = Get-Acl -Path $registryPath
$ruleSID = New-Object System.Security.AccessControl.RegistryAccessRule($sid, 'ReadKey', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
$acl.AddAccessRule($ruleSID)
Set-Acl -Path $registryPath -AclObject $acl
Write-Output "Added 'Interactive' group and SID ($sid) with read (ReadKey) permissions (with inheritance) to the registry key."

#Remove the # below to make sure it will kick off the scheduled task on already enrolled devices
Start-Process "$env:SystemRoot\system32\ClipRenew.exe"
