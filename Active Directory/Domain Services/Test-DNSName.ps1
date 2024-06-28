<# Test-DNSName.ps1
.Description
A high performance DNS resolver in PowerShell, written by Justin Grote at
https://gist.github.com/JustinGrote/d1421208bf1dea22664fc6a198219047

#>

using namespace System.Net
using namespace System.Threading.Tasks
using namespace System.Management.Automation
using namespace System.Collections.Generic

function Test-DNSName ([String[]]$hostnames, [int]$Timeout = 3000) {
<#
.SYNOPSIS
Given a list of DNS names, returns the ones that actually resolve to an actual name
#>
    #A dictionary allows us to be strong typed as well as perform faster
    $taskIndex = [Dictionary[String,Task]]::new()
    #Because GetHostAddresses doesn't remember the origin, we have to use a hashtable to remember which request is which
    [Task[]]$dnsNames = $hostnames.foreach{
        #This returns immediately with a task object, which we save to the dictionary and then output in order to then wait on.
        $task = [net.dns]::GetHostAddressesAsync($PSItem)
        [Void]$taskIndex.Add($PSItem,$task)
        $task
    }
    try {
        #Wait for the tasks to complete or the timeout is reached, whichever comes first
        [void][Task]::WaitAll($dnsNames,$Timeout)
    } catch [MethodInvocationException] {
        Write-Debug "WaitAll Error: $PSItem"
    }
    #Loop through the available keys and only return items that had an actual result (rather than errored)
    $taskIndex.keys.foreach{
        write-debug $PSItem
        if ($taskIndex[$PSItem].Result) {$PSItem}
    }
}
