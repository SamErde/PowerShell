# Work in Progress
# See original at https://github.com/samerde/powershell/windows/Get-NtpClientConfig.ps1

function Test-ThisApproach {
    $computerName = 'ABC-V-12345'

    $Hive = [Microsoft.Win32.RegistryHive]::LocalMachine
    $Path = 'SYSTEM\CurrentControlSet\Services\W32Time'

    try {
        $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
        $SubKey = $BaseKey.OpenSubKey($Path)
        if (!$SubKey) {
            Write-Warning "Registry key '$Path' does not exist." -WarningAction Stop
        } else {
            $Result = foreach ($ValueName in $SubKey.GetValueNames()) {
                [PsCustomObject]@{
                    'ValueName' = if (!$ValueName -or $ValueName -eq '@') { '(Default)' } else { $ValueName }
                    'ValueData' = $SubKey.GetValue($ValueName)
                    'ValueKind' = $SubKey.GetValueKind($ValueName)
                }
            }
        }
    } catch {
        throw
    } finally {
        if ($SubKey) { $SubKey.Close() }
        if ($BaseKey) { $BaseKey.Close() }
    }

    # output on screen
    $Result | Sort-Object ValueName

    # or output to CSV file
    # $Result | Sort-Object ValueName | Export-Csv -Path 'X:\output.csv' -NoTypeInformation
}
