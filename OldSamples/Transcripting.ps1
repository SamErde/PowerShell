# Be sure to set the $TranscriptDir

$TranscriptLog = $env:computername + '_' + $env:username + '_' + (Get-Date -UFormat '%Y%m%d')
Start-Transcript -LiteralPath "$TranscriptDir$TranscriptLog.log" -Append

function Enable-PSTranscription {
    [CmdletBinding()]
    param(
        $OutputDirectory, [Switch] $IncludeInvocationHeader
        )

    ## Ensure the base path exists
    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
    if (-not (Test-Path $basePath)) {
        $null = New-Item $basePath -Force
    }

    ## Enable transcription
    Set-ItemProperty $basePath -Name EnableTranscripting -Value 1

    ## Set the output directory
    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("OutputDirectory")) {
        Set-ItemProperty $basePath -Name OutputDirectory -Value $OutputDirectory
    }

    ## Set the invocation header
    if ($IncludeInvocationHeader) {
        Set-ItemProperty $basePath -Name IncludeInvocationHeader -Value 1
    }
}

function Disable-PSTranscription {
    Remove-Item HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription -Force -Recurse
}
