# ForEach and ForEach-Object are not the same.
# Also see example of looking for $_ in an array.
# https://poshoholic.com/2007/08/31/essential-powershell-understanding-foreach-addendum/

foreach ($character in [char[]]'Poshoholic') {
    if (@('a', 'e', 'i', 'o', 'u') -contains $character ) {
        continue
    }
    $character
}


# Does not work the same as above example because the IF scriptblock
# continues after the first vowel but a consonant is found first.
[char[]]'Poshoholic' | ForEach-Object {
    if (@('a', 'e', 'i', 'o', 'u') -contains $_ ) {
        continue
    }
    $_
}

# A "fix" for the above scriptblock
[char[]]'Poshoholic' | ForEach-Object {
    if ((@('a', 'e', 'i', 'o', 'u') -contains $_) -eq $false ) {
        $_
    }
}

<# Scripting Guy recommendation is that you:

Only use the ForEach-Object cmdlet if you are concerned about saving memory as follows:

    While the loop is running (because only one of the evaluated objects is loaded into memory at one time).

    If you want to start seeing output from your loop faster (because the cmdlet starts the loop the second it has the first
    object in a collection versus waiting to gather them all like the ForEach construct).

You should use the ForEach loop construct in the following situations:

    If you want the loop to finish executing faster (notice I said finish faster and not start showing results faster).

    You want to Break/Continue out of the loop (because you can't with the ForEach-Object cmdlet). This is especially true
    if you already have the group of objects collected into a variable, such as large collection of mailboxes.

https://devblogs.microsoft.com/scripting/weekend-scripter-powershell-speed-improvement-techniques/
#>
