Import-Module ActiveDirectory
Set-ADUser 'Bilbo Baggins' -Add @{drink = 'coffee' }
Get-ADUser 'Bilbo Baggins' -Properties drink | Select-Object *

$Users = Get-ADUser -Filter 'Enabled -eq $true' -Properties drink
$Drinks = $Users | Group-Object drink
$Drinks

$SchemaPath = (Get-ADRootDSE).schemaNamingContext
$DrinkSchema = Get-ADObject -Filter 'Name -like "drink"' -SearchBase $SchemaPath -Properties *
[void]$DrinkSchema
$UserSchema = Get-ADObject -Filter 'Name -like "user"' -SearchBase $SchemaPath -Properties *
$PersonSchema = Get-ADObject -Filter 'Name -like "person"' -SearchBase $SchemaPath -Properties *
[void]$PersonSchema
$Attributes = @()
$Attributes += $UserSchema.maycontain
$Attributes += $userSchema.systemMayContain
$Attributes += $UserSchema.auxiliaryClass
$Attributes += $UserSchema.systemAuxiliaryClass
$Attributes = $Attributes | Sort-Object

$Attributes
$UserSchema.AddedProperties

# Import the Active Directory module
Import-Module ActiveDirectory

# Get the schema object for the drink attribute
$schemaObject = Get-ADObject -Filter { name -eq 'drink' } -SearchBase (Get-ADRootDSE).schemaNamingContext -Properties isDefunct

# Check if the drink attribute is enabled in the schema
if ($schemaObject.isDefunct) {
    Write-Output 'The drink attribute is not enabled.'
} else {
    Write-Output 'The drink attribute is enabled.'
}

# Check if the drink attribute is added to the user class
$userClass = Get-ADObject -Filter { name -eq 'user' } -SearchBase (Get-ADRootDSE).schemaNamingContext -Properties mayContain
if ($userClass.mayContain -contains 'drink') {
    Write-Output 'The drink attribute is added to the user class.'
} else {
    Write-Output 'The drink attribute is not added to the user class.'
}
