# Found this from a user named CoffeeBreak at https://forums.pdfforge.org/t/uninstall-silently-pdf-architect-5/11985/14
# and looks useful. May clean up and write as a function when I have time.


## Step 1 get modules MSI Uninstall Files
## Main module x64, OCR module X64, OCR Module x64, Edit Module x64.

$MsiUninstall = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like 'PDF Architect*' } | Select-Object -Property DisplayName, Uninstallstring

#Empty Array to store uninstall string for Main module, OCR modules and Edit Module Msi files
$MsiUninstallStr = @() 

#Create msiexec PDF Architect Modules Uninstall Strigs
$MsiUninstall.UninstallString | ForEach-Object {
    If (!$_.contains('C:\')) {
        $MsiUninstallStr += '/qn /norestart ' + (($_ -split ' ')[1] -replace '/I', '/X')
    }
}

##Create Empty Array to store Architect 9 Installation Files
$FilesPath = @()
$FilesPathStr = @()

## Extract Files and folders in Program Files
$FilesPath += Get-ChildItem -Path 'C:\Program Files' -Recurse -Force -Include 'PDF Architect*' -ErrorAction 'SilentlyContinue' | Get-ItemProperty | Select-Object -Property Attributes, FullName

## Extract files and folders in programdata
$FilesPath += Get-ChildItem -Path C:\ProgramData -Recurse -Include 'PDF Architect*' -ErrorAction 'SilentlyContinue' | Get-ItemProperty | Select-Object -Property Attributes, FullName

#Extract Files and Folders in Users
$FilesPath += Get-ChildItem -Path C:\users -Recurse -Force -Include 'PDF Architect*' -ErrorAction 'SilentlyContinue' | Get-ItemProperty | Select-Object -Property Attributes, FullName

##Fill Files Path String array
$FilesPathStr = $FilesPath.Fullname

##Create Empty Array to store Registry Key Locations
$RegistryPath = @()
$RegistryPathStr = @()

#List Registrys in HKEY_USERS
$RegistryPath = Get-ChildItem -Path Registry::HKEY_USERS\.DEFAULT\SOFTWARE -Recurse -ErrorAction 'SilentlyContinue' | Where-Object { $_.Name -like '*PDF Architect*' } | Select-Object -Property Name, PSPath
If ($RegistryPath.PSPath -ne $null) {
    $RegistryPathStr += $RegistryPath.PSPath
}

#List Registrys in HKLM:\SYSTEM\CurrentControlSet\Services
$RegistryPath = Get-ChildItem -Path HKLM:\SYSTEM\CurrentControlSet\Services -Recurse -ErrorAction 'SilentlyContinue' | Where-Object { $_.Name -like '*PDF Architect*' } | Select-Object -Property Name, PSPath
If ($RegistryPath.PSPath -ne $null) {
    $RegistryPathStr += $RegistryPath.PSPath
}

#List registrys in HKLM:\Software # key with subkeys
$RegistryPath = Get-ChildItem -Path HKLM:\software | Where-Object { $_.Name -like '*PDF Architect*' } | Select-Object -Property Name, PSPath
If ($RegistryPath.PSPath -ne $null) {
    $RegistryPathStr += $RegistryPath.PSPath
}

#List registry in HKCU:\Software
#List registry in HKEY_USER:\
$RegistryPath =	Get-ChildItem -Path Registry::HKEY_USERS\ -Recurse -ErrorAction 'SilentlyContinue' | Where-Object { $_.Name -like '*PDF Architect*' } | Select-Object -Property Name, PSPath
If ($RegistryPath.PSPath -ne $null) {
    $RegistryPathStr += $RegistryPath.PSPath
}

##-----------------------------------------------------------------------------------------
## Stop Architect Processes in cmd windows
%SYSTEMROOT%\System32\taskkill.exe /F /IM architect.exe
%SYSTEMROOT%\System32\taskkill.exe /F /IM activation-service.exe
##-----------------------------------------------------------------------------------------

##Begin Uninstallation Process
## Silently Uninstall Architect 9 Modules with Msiexec files
$MsiUninstallStr | ForEach-Object {
    Start-Process msiexec.exe -Wait -ArgumentList $_
}

##Delete Program Folder and Files

$FilesPathStr | ForEach-Object {
    Remove-Item $_ -Recurse -Force -ErrorAction 'SilentlyContinue'
}

##Delete References registry keys
$RegistryPathStr | ForEach-Object {
    Remove-Item $_ -Recurse -Force
}

##Delete Installation Pointer Registry keys
$InstallationRegPath = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like 'PDF Architect*' } | Select-Object -Property DisplayName, UninstallString, PSPath

$InstallationRegPath.PSPath | ForEach-Object {
    Remove-Item $_ -Recurse -Force
}
