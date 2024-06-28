function Get-ADObjectFromPipeline {
    <#
        .SYNOPSIS
            Determines the type of an object passed to the pipeline and returns the object as an ADObject.
        .DESCRIPTION
            Determines the type of an object passed to the pipeline and returns the object as an ADObject. Potentially
            useful for normalizing input to other functions.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        $Identity
    )

    begin {
        Import-Module ActiveDirectory
        $GlobalCatalog = Get-ADDomainController -Discover -Service GlobalCatalog

        if ($Identity -is [Microsoft.ActiveDirectory.Management.ADUser]) {
            # We have an ADUser object
            # Might want to normalize the type to an ADObject IF we can get sidHistory from an ADObject
        }
        if ($Identity -is [Microsoft.ActiveDirectory.Management.ADComputer]) {
            # We have an ADComputer object
            # Might want to normalize the type to an ADObject IF we can get sidHistory from an ADObject
        }
        if ($Identity -is [string]) {
            # Find an AD object and determine its type
            $Identity = Get-ADObject -Filter "Name -eq `"$Identity`""
        }
        $IdentityType = $Identity.ObjectClass
    }

    process {
        switch ($IdentityType) {
            'user' {
                # Not Complete
                $User = Get-ADUser -Identity $Identity -Properties PrimaryGroup,SidHistory
            }
            'computer' {
                # Not Complete
                $Computer = Get-ADComputer -Identity $Identity -Properties PrimaryGroup,SidHistory
            }
            Default {
                Write-Error "Identity type not supported."
            }
        }
    }

    end {
        # Do something and/or return the resulting object to the pipeline.
        if ($User) {
            $User
        }
        if ($Computer) {
            $Computer
        }
    }
}
