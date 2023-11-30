
# Use it to create a variable in a different scope. The -Scope parameter can be clearer than using $global:foo = 1
New-Variable -Scope Global -Name VariableName

# Use it to create a constant variable or a read-only variable
New-Variable -Name pi -Value $([math]::Pi) -Option constant

# Append to a very long command to output the result into an output variable,
# rather than modify the beginning to add $variable = my command.
# You can often also use the common parameter -OutVariable instead of this.
Get-ChildItem | Set-Variable -Name VariableName

# Use when you want to use a variable to dynamically set the name of a new variable. 

    # Example 1: Create a variable for each item in an array.
    $List = @("01","02","03","04","05")
    foreach ($item in $List) {
        New-Variable -Name "Node$item" -Value "server$item" -Verbose
    }

    # Example 2: This example creates "hostEntry1_name" = "server01" (for 1 - 5).
    $CurrentResult = @("server01","server02","server03","server04","server05")
    $RecordHostCounter = 0
    foreach ($item in $CurrentResult) {
        $RecordHostCounter++
        Set-Variable -Name ('hostEntry{0}_name' -f $RecordHostCounter) -Value $item -Verbose
    }

# Use it to put the contents of the clipboard into a variable.
Get-Clipboard | Set-Variable -Name ClipboardContents

# Of course, you can also still use this, but will not get as much control over the variable that is created.
Get-Clipboard -OutVariable ClipboardContents

# Use to copy variable from one PowerShell instance to another via the clipboard. 
# Example: Check for admin permissions. If they have them, open an elevated prompt and 
# carry the contents of a variable into the elevated window via the clipboard.

<# Other Possible Uses 
 - Use it to more easily create a variable from a string in an array.

 - Use New-Variable when you want to put a space in a variable name--but that is a BAD idea!

 - Use it to create variables in loops. Example: Loop through a list of vCenter servers to connect to and create 
   a different varable for each server.
#>
