function New-Function {
    <#
        .SYNOPSIS
        Create a new advanced function from a template.

        .DESCRIPTION
        This function creates a new function from a template and saves it to a file with the name of the function.
        It takes values for the function's synopsis, description, and alias as parameters and populates comment-
        based help for the new function automatically.

        .PARAMETER Name
        The name of the new function to create. It is recommended to use ApprovedVerb-Noun for names.
        
        .PARAMETER Synopsis
        A synopsis of the new function.

        .PARAMETER Description
        A description of the new function.

        .PARAMETER Alias
        Optionally define an alias for the new function.

        .PARAMETER Path
        The path of the directory to save the new script in.

        .EXAMPLE
        New-Function -Name "Get-Demo" -Synopsis "Get a demo." -Description "This function gets a demo." -Alias "Get-Sample"

        .NOTES
        Author: Sam Erde
        Version: 0.0.1
        Modified: 2024-07-02
    #>

    [CmdletBinding()]
    [Alias('New-Script')]
    param (
        # The name of the new function.
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,

        # Synopsis of the new function.
        [Parameter()]
        [string]
        $Synopsis,

        # Description of the new function.
        [Parameter()]
        [string]
        $Description,

        # Optional alias for the new function.
        [Parameter()]
        [string]
        $Alias,

        # Path of the directory to save the new function in.
        [Parameter()]
        [string]
        $Path
    )

    # Set the script path and filename. Use current directory if no path specified.
    if (Test-Path -Path $Path -PathType Container) {
        $ScriptPath = [System.IO.Path]::Combine($Path,"$Name.ps1")
    } else {
        $ScriptPath = ".\$Name.ps1"
    }

    # Create the function builder string builder and function body string.
    $FunctionBuilder = [System.Text.StringBuilder]::New()
    $FunctionBody = @'
function New-Function {
    <#
        .SYNOPSIS
        __SYNOPSIS__

        .DESCRIPTION
        __DESCRIPTION__

        .PARAMETER Parameter1
        __PARAMETER1__

        .PARAMETER Parameter2
        __PARAMETER2__

        .EXAMPLE
        __EXAMPLE__

        .NOTES
        Author: Sam Erde
        Version: 0.0.1
        Modified: __DATE__
    #>

    [CmdletBinding()]
    __ALIAS__
    param (

    )

    begin {

    } # end begin block
    
    process {

    } # end process block
    
    end {

    } # end end block

} # end function New-Function
'@

    # Replace template placeholders with strings from parameter inputs.
    $FunctionBody = $FunctionBody -Replace 'New-Function', $Name
    $FunctionBody = $FunctionBody -Replace '__SYNOPSIS__', $Synopsis
    $FunctionBody = $FunctionBody -Replace '__DESCRIPTION__', $Description
    $FunctionBody = $FunctionBody -Replace '__DATE__', (Get-Date -Format 'yyyy-MM-dd')
    # Set an alias for the new function if one is given in parameters.
    if ($PSBoundParameters.ContainsKey('Alias')) {
        $FunctionBody = $FunctionBody -Replace '__ALIAS__', "[Alias(`'$Alias`')]"
    } else {
        $FunctionBody = $FunctionBody -Replace '__ALIAS__', ''
    }

    # Create the new file.
    [void]$FunctionBuilder.Append($FunctionBody)
    $FunctionBuilder.ToString() | Out-File -FilePath $ScriptPath -Encoding utf8 -Force

} # end function New-Function
