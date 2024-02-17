$sb = [System.Text.StringBuilder]::New()
$sb.Append('a').AppendFormat('{0} {1}', 'c', 'd').AppendLine()

$items = Get-ChildItem -Recurse | Where-Object { $_.Name -match '^*.ps1$' }

foreach ($script in $items) {
    $null = $sb.Append((Get-Content -Path $script.FullName -Raw))
    $null = $sb.AppendLine('')
}

$sb.ToString() | Out-File -FilePath $FilePath -Encoding utf8 -Force
