Get-Module -ListAvailable -Refresh -Name Microsoft.Entra* | Format-Table Name, RequiredModules

Write-Host ("{0} seconds:`tList commands with '`Get-Command -Module Microsoft.Entra.*' `n" -f [math]::Round( (Measure-Command {
    Get-Command -Module Microsoft.Entra.*
} ).TotalSeconds, 2))

@('Applications', 'Authentication', 'DirectoryManagement', 'Governance', 'Groups', 'Reports', 'SignIns', 'Users') | ForEach-Object {
    Write-Host ("{0} seconds:`tMicrosoft.Entra.$_" -f [math]::Round((Measure-Command {
        Import-Module -Name "Microsoft.Entra.$_"
    }).TotalSeconds), 2)
}
