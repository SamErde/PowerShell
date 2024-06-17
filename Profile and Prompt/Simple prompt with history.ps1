function Prompt
{
    Write-Host ("PS " + $(get-date) + " [$((Get-History).Count)] " + "$pwd>") #-ForegroundColor White
    Write-Host ">" -NoNewline #-ForegroundColor White
    return " "
}
