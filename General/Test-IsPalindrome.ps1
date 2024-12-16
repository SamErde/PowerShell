function Test-IsPalindrome {
    <#
    .SYNOPSIS
    Test a string to see if it is a palindrome.

    .DESCRIPTION
    This function tests a string to see if it is a palindrome. A palindrome is a word, phrase, number, or other sequence of characters that reads the same forward and backward.

    .PARAMETER String
    The string to test.

    .EXAMPLE
    Test-IsPalindrome -String "racecar"

    The string "racecar" is a palindrome, so the function returns $true.

    .EXAMPLE
    '() ()' | Test-IsPalindrome

    The string "() ()" is not a palindrome, so the function returns $false.

    .EXAMPLE
    '() )(' | Test-IsPalindrome

    The string "() )(" is a palindrome, so the function returns $true.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # The string to test
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]
        $String
    )

    process {
        $ReversedString = -join ($String.ToLower().ToCharArray() | ForEach-Object { $_ })[-1.. - ($String.Length)]
        "`n$String    ||    $ReversedString" | Write-Verbose
        $Result = $String -eq $ReversedString
    }

    end {
        $Result
    }
}
