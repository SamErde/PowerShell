# Get command autocomplete suggestions with PSReadLine  

First, force an upgrade of the module which is quasi-bound to our currently deployed build of Windows 10. FMI: [https://github.com/PowerShell/PowerShellGetv2/issues/644#issuecomment-592137971](https://github.com/PowerShell/PowerShellGetv2/issues/644#issuecomment-592137971)  

1. Close ALL PowerShell instances.  

2. Open an elevated command prompt.  

3. Install the latest version of PSReadLine  

    To update the Windows PowerShell 5.1 module, run:  

    ```powershell
    powershell.exe -noprofile -command "Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease"
    ```

    To update the PowerShell Core 7+ module, run:  

    ```powershell
    pwsh.exe -noprofile -command "Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease"
    ```

4. Add the following block to your PowerShell profile[s]. Note that Windows PowerShell 5.1 does not support the 'HistoryAndPlugin' predictive text source.  

    ```powershell
    # Set PSReadLine Preferences
    Set-PSReadLineOption -PredictionViewStyle ListView
    if ($host.Version -like "5.*") {
        Set-PSReadLineOption -PredictionSource History
    }
    else {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    }
    ```
