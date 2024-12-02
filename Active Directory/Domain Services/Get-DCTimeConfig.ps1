# WIP

# Check domain controllers' time sources.
$DomainControllers = Get-ADDomainController -Filter *
foreach ($DC in $DomainControllers) {
    $TimeSource = w32tm /query /status /computer:$DC.HostName | Select-String 'Source'
    [PSCustomObject]@{
        Hostname   = $DC.HostName
        TimeSource = $TimeSource -replace 'Source: ', ''
    }
}

# Check the time settings on each domain controller using Get-CimInstance
foreach ($DC in $DomainControllers) {
    $TimeSettings = Get-CimInstance -ClassName Win32_TimeZone -ComputerName $DC.HostName
    [PSCustomObject]@{
        Hostname     = $DC.HostName
        Caption      = $TimeSettings.Caption
        Description  = $TimeSettings.Description
        StandardName = $TimeSettings.StandardName
        DaylightName = $TimeSettings.DaylightName
    }
}

# Check the NTP server and Win32Time service status on each domain controller using Get-CimInstance
foreach ($DC in $DomainControllers) {
    $NTPServer = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $DC.HostName | Select-Object -ExpandProperty DomainRole
    $Win32TimeService = Get-CimInstance -ClassName Win32_Service -Filter "Name='w32time'" -ComputerName $DC.HostName

    [PSCustomObject]@{
        Hostname                  = $DC.HostName
        NTPServer                 = $NTPServer
        Win32TimeServiceState     = $Win32TimeService.State
        Win32TimeServiceStartMode = $Win32TimeService.StartMode
    }
}
