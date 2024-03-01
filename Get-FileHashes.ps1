$csv = "H:\files.csv"
$path = "H:\Cleaned"
$photos = Get-ChildItem -Path $path -Exclude *.db -Recurse -File
foreach ($file in $photos) 
{
    $fInfoProperty = [ordered]@{
        Name        = $file.Name
        FullName    = $file.FullName
        Length      = $file.Length
        Hash        = (Get-FileHash -Algorithm MD5 -Path $file.FullName).Hash
    } 
    $fInfo = New-Object -TypeName psobject -Property $fInfoProperty
    $fInfo | Export-Csv -Path $csv -Append -NoTypeInformation
}
