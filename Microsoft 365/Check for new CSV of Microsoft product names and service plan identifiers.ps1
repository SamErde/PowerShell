# Check Microsoft Learn for a new download of the Product Names and Service Plan Identifiers CSV file.
$Response = Invoke-WebRequest -Uri 'https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference'
$LicensingCsvDownloadLink = ( $Response.Links.Where({ $_.href -match 'licensing.csv' -or $_.href -match 'Product%20names%20and%20service%20plan' }) ).href
$LicensingCsvDownloadLink
