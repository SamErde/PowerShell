function Get-DomainController {
    [CmdletBinding()]
    param (

    )

    begin {
        $AllDomainControllers = New-Object -TypeName System.Collections.Generic.List[System.DirectoryServices.ActiveDirectory.DomainController]
    } # end begin

    process {
        $Context = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::New([System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain)
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)

        foreach ($dc in $Domain.DomainControllers) {
            $AllDomainControllers.Add($dc)
        }
    } # end process

    end {
        $AllDomainControllers
    } # end end
} # end function Get-DomainController
