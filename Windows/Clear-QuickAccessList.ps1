# Clear the Quick Access list in Windows Explorer
$QuickAccessFilePath = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\f01b4d95cf55d32a.automaticDestinations-ms"
if (Test-Path -Path $QuickAccessFilePath) {
    Remove-Item $QuickAccessFilePath -Confirm:$false -Force
}
