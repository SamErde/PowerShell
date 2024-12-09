function Get-RepositoryInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
    )

    $RepositoryRoot = [System.IO.Path]::Combine($PSScriptRoot, '..', '..')

    [PSCustomObject]$Info = @{
        NumberOfScripts = (Get-ChildItem $RepositoryRoot -Filter *.ps1 -File -Recurse).Count
        NumberOfFOlders = (Get-ChildItem $RepositoryRoot -Directory -Recurse).Count
        Categories      = (Get-ChildItem -Path $RepositoryRoot -Directory -Exclude '.github').Name
        CategoryList    = (Get-ChildItem -Path $RepositoryRoot -Directory -Exclude '.github').Name -replace 'DDI', 'DDI (DNS, DHCP, IPAM)' -join ', '
    }

    $Info
}

Get-RepositoryInfo
