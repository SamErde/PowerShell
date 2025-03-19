function Measure-CommandCount {
    # Count the number of unique commands available.
    (Get-Command | Sort-Object -Property Source, Version | Group-Object -Property Name, Source -NoElement |
        Measure-Object).Count
}

function Measure-ModuleInventory {
    <#
        List all available modules and the commands in each one.
    #>
    $Inventory = [ordered]@{}

    $Commands = Get-Command | Sort-Object -Property Source, Name, Version |
        Select-Object Source, Name, Version | Group-Object -Property Source, Name -NoElement |
            Select-Object -ExpandProperty Name

    $Commands | ForEach-Object {
        $Module, $Command = $_ -split ', '

        if ([string]::IsNullOrEmpty($Module)) {
            $Module = '_UnnamedSourceModule_'
        }

        if ($Inventory.Contains($Module)) {
            $Inventory[$Module] += $Command
        } else {
            $Inventory[$Module] = @($Command)
        }
    }

    $Inventory
}

$Inventory = Measure-ModuleInventory
$Inventory.Count

$CommandCount = 0
foreach ($item in $Inventory.GetEnumerator()) {
    $CommandCount += $item.Value.Count
}
$CommandCount
