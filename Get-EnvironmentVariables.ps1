function Get-EnvironmentVariable {
    [CmdletBinding()]
    [Alias("genv")]
    param (
        
    )
    
    begin {
        
    }
    
    process {
        Get-ChildItem env:
    }
    
    end {
        
    }
}
