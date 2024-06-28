function Find-DeepestOU {
    <#
        .SYNOPSIS
            Find the deepst level of OU
        .DESCRIPTION
            Trying to recreate a concept for a recursively looping script that a co-worker described to me. I'm not getting it yet!
    #>
    param (
        [string]$OU = (Get-ADRootDSE).rootDomainNamingContext,
        [int]$CurrentDepth = 0
    )

    $CurrentDeepest = $CurrentDepth
    $CurrentDepth++

    $SubOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $OU -SearchScope OneLevel
    if ($SubOUs.Count -eq 0) {
        Return @{
            Depth = $CurrentDeepest
            OU=$OU
        }
        
        foreach ($ou in $SubOUs) {
            Return (Find-Deepest $ou $CurrentDepth)
        }
    }
}
