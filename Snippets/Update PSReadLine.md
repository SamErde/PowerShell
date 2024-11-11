# Update PSReadLine

Close ALL instances of PowerShell, including VS Code, and then run this from an elevated command prompt:

``` shell
pwsh.exe -noprofile -command "Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease"
powershell.exe -noprofile -command "Install-Module PSReadLine -Force -SkipPublisherCheck
```

Add this to your PowerShell profiles. Windows PowerShell does not support 'HistoryAndPlugin'.

## Set PSReadLine Preferences

```powershell
Set-PSReadLineOption -PredictionViewStyle ListView
if ($host.Version -like "5.*") {
    Set-PSReadLineOption -PredictionSource History
}
else {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
}
```
