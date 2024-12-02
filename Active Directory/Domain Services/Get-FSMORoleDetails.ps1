#WIP

# Get the hostname and AD site location of domain controllers that hold the AD FSMO roles.
$FSMORoles = Get-ADForest | Select-Object -ExpandProperty SchemaMaster, DomainNamingMaster
$FSMORoles += Get-ADDomain | Select-Object -ExpandProperty PDCEmulator, RIDMaster, InfrastructureMaster

# Get the details of each FSMO role holder
foreach ($role in $FSMORoles) {
    $DC = Get-ADDomainController -Identity $role
    [PSCustomObject]@{
        Hostname  = $DC.HostName
        IPAddress = $DC.IPAddress
        ADSite    = $DC.Site
    }
}
