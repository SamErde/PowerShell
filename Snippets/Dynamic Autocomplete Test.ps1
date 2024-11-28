# Windows PowerShell: Dynamically get Azure environment names for parameter autocomplete and validation in Windows PowerShell (5.1).
function Connect-AzureTestCompatible {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [ArgumentCompleter( {
                param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
                $Global:EnvironmentNames = (Get-MgEnvironment).Name; $Global:EnvironmentNames
            } )]
        [ValidateScript({
                if ($_ -in $Global:EnvironmentNames) {
                    $true
                } else {
                    throw "`n$_ is not a valid environment name. Please use one of the following: $($Global:EnvironmentNames -join ', ')"
                }
            })]
        [string]$Environment
    )
    Connect-MgGraph -Environment $Environment
}



# PowerShell Core: Get Azure environment names for tab autocomplete in function parameters. Requires PowerShell Core (6+).
Class EnvironmentName : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        $EnvironmentNames = (Get-MgEnvironment).Name
        return [string[]] $EnvironmentNames
    }
}

function Connect-GraphTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet([EnvironmentName])]
        [string]$Environment
    )

    Connect-MgGraph -Environment $Environment
}
