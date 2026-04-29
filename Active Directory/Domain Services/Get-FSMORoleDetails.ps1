#WIP

# Get the hostname and AD site location of domain controllers that hold the AD FSMO roles.
# Note: -ExpandProperty only accepts one property at a time; collect each role separately.
$Forest = Get-ADForest
$Domain = Get-ADDomain
$FSMORoles = @(
    $Forest.SchemaMaster
    $Forest.DomainNamingMaster
    $Domain.PDCEmulator
    $Domain.RIDMaster
    $Domain.InfrastructureMaster
)

# Get the details of each FSMO role holder
foreach ($role in $FSMORoles) {
    $DC = Get-ADDomainController -Identity $role
    [PSCustomObject]@{
        Hostname  = $DC.HostName
        IPAddress = $DC.IPAddress
        ADSite    = $DC.Site
    }
}
