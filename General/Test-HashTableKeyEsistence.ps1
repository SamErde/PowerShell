function Test-HashTableKeyExistence {
<#
    .SYNOPSIS
    Check if a key exists in a hash table.

    .DESCRIPTION
    This function checks whether a specified key exists in a hash table, even if the associated value is $null.

    .PARAMETER HashTable
    The hash table to check. Accepts input from the pipeline.

    .PARAMETER KeyToCheck
    The key to check for existence in the hash table.

    .INPUTS
    Hashtable: accepts hashtable object from the pipeline.
    String: accepts key name as a string.

    .OUTPUTS
    Boolean: Returns true if the key exists, false otherwise.

    .EXAMPLE
    $HashTable = @{
        Key1 = 'Value1'
        Key2 = $null  # Note: this key exists but has null value
        Key3 = 'Value3'
    }
    Test-HashTableKeyExistence -HashTable $HashTable -KeyToCheck 'Key2'

    Tests if 'Key2' exists in the provided hash table.

    .EXAMPLE
    $HashTable = @{
        KeyA = 'ValueA'
        KeyB = 'ValueB'
    }

    $HashTable | Test-HashTableKeyExistence -KeyToCheck 'KeyC'

    Tests if 'KeyC' exists in the provided hash table.

    .NOTES
    Author: Sam Erde
    Version: 1.0
    Date: 2026-01-05
#>
    [CmdletBinding()]
    [OutputType([bool])]
    param (

        # The hash table object to check.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [hashtable]$HashTable,

        # The name of the key to check.
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyToCheck
    )

    process {
        if ($HashTable.ContainsKey($KeyToCheck)) {
            Write-Verbose "The key [$KeyToCheck] exists in the hash table."
            $true
        } else {
            Write-Verbose "The key [$KeyToCheck] does not exist in the hash table."
            $false
        }
    }
}
