function Get-DSReg {
    <#
        .SYNOPSIS
            Convert the output of dsregcmd.exe to a PowerShell object.
    #>
    $DSReg = [PSCustomObject]@{}
    $DSRegCmdOutput = (dsregcmd /status | Select-String '(^.*?) : (.*$)').Matches.Value
    foreach ($line in $DSRegCmdOutput) {
        $Detail = $line.Split(':', 2)
        $DetailName = ($Detail[0]).Replace(' ', '').Replace('-', '').Trim()
        $RawValue = ($Detail[1]).Trim()
        switch ($RawValue) {
            'NO' { $CleanValue = $false }
            'YES' { $CleanValue = $true }
            'NOT SET' { $CleanValue = $null }
            'none' { $CleanValue = $null }
            Default { $CleanValue = $RawValue }
        }

        $DSReg | Add-Member -MemberType NoteProperty -Name $DetailName -Value $CleanValue
    }

    $DSReg
}
