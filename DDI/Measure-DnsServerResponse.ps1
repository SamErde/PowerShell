# Measure the number of network hops and the average response time for a query to a DNS server.

function Measure-DnsResponseTime {
    <#
    .SYNOPSIS
    Measure average query response time from a DNS server.

    .PARAMETER DnsServer
    The DNS server name or IP address to query.

    .PARAMETER TargetName
    The domain or host name to query.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            HelpMessage = 'The DNS server name or IP address to query.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $DnsServer,

        [Parameter(
            Mandatory,
            Position = 1,
            HelpMessage = 'The domain or host name to resolve.'
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $TargetName,

        # Number of times to query the DNS server for the target name.
        [Parameter(
            HelpMessage = 'The number of times to query the DNS server for the target name.'
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [int16]
        $QueryCount = 100
    )
    $queryTimes = @()
    Write-Host "Querying DNS server $DnsServer for $TargetName $QueryCount times: " -NoNewline -ForegroundColor Green
    for ($i = 0; $i -lt $QueryCount; $i++) {
        Write-Host '.' -NoNewline -ForegroundColor Yellow
        try {
            $QueryTimes += (Measure-Command { Resolve-DnsName -Server $DnsServer -Name $TargetName -DnsOnly -NoHostsFile }).TotalMilliseconds
        } catch {
            Write-Output "Failed to resolve DNS query: $_"
            return
            # To Do: Add error handling. Change return to a continue and track how many times it failed, then reduce the result count for the average--but also show a factor for how reliable the server was.
        }
    }
    Write-Host '. Done!' -ForegroundColor Green
    "Times: $($QueryTimes -join ', ')" | Write-Verbose
    $AverageTime = [math]::Round( ($QueryTimes | Measure-Object -Average).Average, 2 )
    Write-Host "Average response time: $AverageTime ms`n" -ForegroundColor White
    $AverageTime
}

function Measure-NetworkHops {
    <#
    .SYNOPSIS
    Measure the number of network hops and get basic trace route details for a given server.

    .PARAMETER Server
    The server name or IP address to measure network hops to.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [OutputType([int])]
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            HelpMessage = 'The DNS server name or IP address to measure network hops to.')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
    )
    Write-Host "Measuring network hops to $Server..." -ForegroundColor Cyan
    $TestResult = Test-NetConnection -ComputerName $Server -TraceRoute -InformationLevel Detailed
    $Result = [PSCustomObject]@{
        Server             = $Server
        PingSucceeded      = $TestResult.PingSucceeded
        PingRoundTripTime  = $TestResult.PingReplyDetails.RoundtripTime
        Hops               = $TestResult.TraceRoute.Count
        # NameResolutionSucceeded = $TestResult.NameResolutionSucceeded
        # ResolvedName            = $TestResult.DNSOnlyRecords.Name
        MatchingIpsecRules = $TestResult.MatchingIpsecRules
    }
    $Result
}

# Example Usage: Measure network hops and DNS response time for a list of DNS servers.
$DnsServers = @('8.8.8.8', '8.8.4.4', '1.1.1.1', '9.9.9.9')
$DnsServers | ForEach-Object {
    Measure-NetworkHops -Server $_
    Measure-DnsResponseTime -DnsServer $_ -TargetName 'day3bits.com' -QueryCount 10 | Out-Null
}

# Example Usage: Measure network hops and DNS response time for all domain controllers in the current domain.
$TestResults = New-Object System.Collections.Generic.List[PSObject]
$Servers = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
$Servers | ForEach-Object {
    $NetworkHops = Measure-NetworkHops -Server $_
    $Results = [PSCustomObject]@{
        Server                   = $NetworkHops.Server
        NetworkHops              = $NetworkHops.Hops
        PingSucceeded            = $NetworkHops.PingSucceeded
        PingRoundTripTime        = $NetworkHops.PingRoundTripTime
        AverageQueryResponseTime = Measure-DnsResponseTime -DnsServer $_ -TargetName 'github.com' -QueryCount 10
    }
    $TestResults.Add($Results) | Out-Null
}
$TestResults | Format-Table -AutoSize
