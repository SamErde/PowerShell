<#
  .SYNOPSIS
  Disable Large Send Offload on all network adapters.
  
  .DESCRIPTION
  This script disabled Large Send Offload (LSO) on all network adapters. It resolves a potential issue with Microsoft Defender
  for Identity (MDI) in which you might receive a health alert that states "Some netowkr traffic is not being analyzed." 
  
  WARNING: Depending on your configuration, this might cause a brief loss of network connectivity when the adapter configuration changes.
  
  .NOTE
  Reference: https://docs.microsoft.com/en-us/defender-for-identity/troubleshooting-known-issues#vmware-virtual-machine-sensor-issue
#>

# Disable Large Send Offload (LSO) if it is enabled on domain controllers' virtual NICs.
Write-Output "`nDisabling Large Send Offload..."
(Get-NetAdapterAdvancedProperty).Where({ $_.DisplayName -Match "^Large*" }) | Disable-NetAdapterLso -Verbose -WhatIf

Write-Output "`nNetwork adapters with Large Send Offload enabled: `n"
Get-NetAdapterAdvancedProperty | Where-Object { $_.DisplayName -Match "^Large*" }
