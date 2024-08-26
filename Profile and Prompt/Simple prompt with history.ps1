function PromptPlain {
    Write-Host ('PS ' + $(Get-Date) + " [$((Get-History).Count)] " + "$pwd>") #-ForegroundColor White
    Write-Host '>' -NoNewline #-ForegroundColor White
    return ' '
}

function Prompt {
    Write-Host "[$((Get-History).Count)] " -NoNewline -ForegroundColor Cyan
    Write-Host "$([math]::Ceiling((((Get-History)[-1]).EndExecutionTime - ((Get-History)[-1]).StartExecutionTime).TotalMilliseconds))ms " -NoNewline -ForegroundColor Yellow
    Write-Host "$($PWD.ToString().Replace($HOME,'~'))" -ForegroundColor Cyan
    Write-Host '>' -NoNewline -ForegroundColor White
    return ' '
}
