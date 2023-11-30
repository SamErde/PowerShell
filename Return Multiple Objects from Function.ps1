function Get-Food {
    $TreeFruit = @("Apple","Orange","Peach")
    $Squash = @("Pumpkin","Acorn Squash","Winter Squash")
    $RootVegetable = @("Potato","Sweet Potato","Turnip","Radish")

    Return @{
        TreeFruit = $TreeFruit
        Squash = $Squash
        RootVegetable = $RootVegetable
    }
}
$Results = Get-Food

Write-Output @"
Tree Fruit:
$($Results['TreeFruit'] -join ', ')

Squash:
$($Results['Squash'] -join ', ')

Root Vegetables:
$($Results['RootVegetable'] -join ', ')
"@


# Problematic solution that simply returns multiple objects
function Get-Food {
    $TreeFruit = @("Apple","Orange","Peach")
    $Squash = @("Pumpkin","Acorn Squash","Winter Squash")
    $RootVegetable = @("Potato","Sweet Potato","Turnip","Radish")

    Return @($TreeFruit, $Squash, $RootVegetable)
    # Or just: $TreeFruit, $Squash, $RootVegetable
}
$Food = Get-Food

# Recreate the arrays that might contain the food found with imatch:
$TreeFruit = $Food -imatch "Apple"
$Squash = $Food -imatch "Squash"
$RootVegetable = $Food -imatch "Turnip"

# Recreate the arrays by index and hope you get the order right:
$TreeFruit = $Food[0]
$Squash = $Food[1]
$RootVegetable = $Food[2]

Write-Output @"
Tree Fruit:
    $($TreeFruit.GetEnumerator())

Squash:
    $($Squash.GetEnumerator())

Root Vegetable:
    $($RootVegetable.GetEnumerator())
"@
