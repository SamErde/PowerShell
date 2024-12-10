function Test-WinREEnabled {
    # This requires admin rights to enable WinRE with reagentc.exe.
    [CmdletBinding()]
    param()

    $ReAgentXmlPath = 'C:\Windows\System32\Recovery\ReAgent.xml'
    $WinReEnabled = $false

    if (Test-Path $reAgentXmlPath) {
        $ReAgentXml = [xml](Get-Content $reAgentXmlPath)
        $WinReBcdId = $ReAgentXml.WindowsRE.WinreBCD.id

        if ([string]::IsNullOrEmpty($winreBcdId)) {
            Write-Verbose "No `'WindowsRE.WinreBCD`' id was found in $reAgentXmlPath`'."
            $WinReEnabled = $false
        } elseif ($winreBcdId -eq '00000000-0000-0000-0000-000000000000') {
            Write-Verbose "The `'WindowsRE.WinreBCD`' id in $reAgentXmlPath`' contains all zeroes."
            $WinReEnabled = $false
        } else {
            Write-Verbose "The `'WindowsRE.WinreBCD`' id in $reAgentXmlPath`' is not empty and does not contain all zeroes."
            $WinReEnabled = $true
        }
    }

    if ($WinReEnabled -eq $false) {
        reagentc.exe /enable
    }
}
