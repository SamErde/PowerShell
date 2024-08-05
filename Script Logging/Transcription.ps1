# Get command history
(Get-History).Where( {$_.StartExecutionTime -gt ((Get-Date).Date)} ).CommandLine


# Start a transcript
$TranscriptLog = $env:computername+"_"+$env:username+"_"+(Get-Date -UFormat "%Y%m%d")
Start-Transcript -LiteralPath "$TranscriptDir$TranscriptLog.log" -Append


# Enable PowerShell Transcription
function Enable-PSTranscription {
    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
    if (-not (Test-Path $basePath)) { $null = New-Item $basePath -Force }
    Set-ItemProperty $basePath -Name EnableTranscripting -Value 1
    Set-ItemProperty $basePath -Name OutputDirectory -Value "$env:USERPROFILE\OneDrive\PSTranscripts\$env:COMPUTERNAME\"
    Set-ItemProperty $basePath -Name EnableInvocationHeader -Value 1

    $basePath = "HKLM:\Software\Policies\Microsoft\PowerShellCore\Transcription"
    if(-not (Test-Path $basePath)) { $null = New-Item $basePath -Force  }
    Set-ItemProperty $basePath -Name EnableTranscripting -Value 1
    Set-ItemProperty $basePath -Name OutputDirectory -Value "$env:USERPROFILE\OneDrive\PSTranscripts\$env:COMPUTERNAME\PSCore\"
    Set-ItemProperty $basePath -Name EnableInvocationHeader -Value 1
}
Enable-PSTranscription
