# Remove Advanced Threat Analytics (ATA) after Microsoft Defender for Identity (MDI) is installed.
$ATA = Get-CimInstance -Class Win32_Product | Where-Object{$_.Name -like "Microsoft Advanced Threat *"}
$MDI = Get-CimInstance -Class Win32_Product | Where-Object{$_.Name -eq "Azure Advanced Threat Protection Sensor"}

if ($MDI) {
  Write-Output "Installation found: $ATA"
  $ATA.Uninstall()
 }

 # NOTE: Removal of the MDI Sensor seems to work better by running "Azure Advanced Threat Analytics Sensor.msi /uninstall"

 # Remove old version: 
 & "C:\ProgramData\Package Cache\{40d9b2a4-2356-4746-91dc-246f3b6b5bcb}\Azure ATP Sensor Setup.exe" /uninstall /quiet
 