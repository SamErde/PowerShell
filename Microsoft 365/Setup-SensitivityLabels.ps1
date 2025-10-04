# https://learn.microsoft.com/en-us/entra/identity/users/groups-assign-sensitivity-labels?tabs=microsoft

$grpUnifiedSetting = Get-MgBetaDirectorySetting | Where-Object { $_.Values.Name -eq 'EnableMIPLabels' }
$grpUnifiedSetting.Values

$params = @{
    Values = @(
        @{
            Name  = 'EnableMIPLabels'
            Value = 'True'
        },
        @{
            Name  = 'EnableGroupCreation'
            Value = 'False'
        }
    )
}

Update-MgBetaDirectorySetting -DirectorySettingId $grpUnifiedSetting.Id -BodyParameter $params

$Setting = Get-MgBetaDirectorySetting -DirectorySettingId $grpUnifiedSetting.Id
$Setting.Values

# https://learn.microsoft.com/en-us/purview/create-sensitivity-labels?tabs=classic-label-scheme#create-and-configure-sensitivity-labels

Connect-IPPSSession -ShowBanner:$false -BypassMailboxAnchoring -UserPrincipalName $MyUPN
Execute-AzureAdLabelSync



# https://learn.microsoft.com/en-us/purview/sensitivity-labels-sharepoint-onedrive-files
Import-Module -Name Microsoft.Online.SharePoint.PowerShell
Set-SPOTenant -EnableAIPIntegration $true
Set-SPOTenant -EnableSensitivityLabelforPDF $true
