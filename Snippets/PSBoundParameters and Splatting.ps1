# Example from Salad Promblems in the PowerShell Community
# https://discord.com/channels/180528040881815552/447476117629304853/1204491366785228840

function Get-Thing {
    [CmdletBinding()]
    param(
        [string]$path
    )

    $param = @{
        recurse   = $true
        path      = 'c:\temp'
        directory = $true
    }
    if ($PSBoundParameters['path']) {
        $param['path'] = $PSBoundParameters['path']
    }
    Get-ChildItem @param
}

Get-Thing -path 'C:\AMD'

# Side note: I really like the use of splatting parameters in this example. I've never used that!
