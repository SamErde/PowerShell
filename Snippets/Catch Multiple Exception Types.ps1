# Path to a non-existant file
$Path = "C:\Temp\Non-Existant.csv"

# Catch specific exception types and catch multiple types at once
try {
    Import-Csv -Path $path -ErrorAction Stop
}
catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException] {
    Write-Output "The path or file was not found: [$path]"
}
catch [System.IO.IOException] {
    Write-Output "IO error with the file: [$path]"
}
