# Check if a string exists as a key in a hash table
$StringToCheck = "SomeString"
if ($null = $HashTable[$StringToCheck]) {
    Write-Output "The key [$StringToCheck] does not exist in the hash table"
}
else {
    Write-Output "The key [$StringToCheck] exists in the hash table"
}
