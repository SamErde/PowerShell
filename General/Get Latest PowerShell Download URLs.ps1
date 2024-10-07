# Get the URLs to download the latest builds of PowerShell
$latest = (Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest')
$latest.assets.browser_download_url
