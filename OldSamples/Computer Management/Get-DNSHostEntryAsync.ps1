Function Get-DNSHostEntryAsync {
    <#
        .SYNOPSIS
            Performs a DNS Get Host asynchronously 

        .DESCRIPTION
            Performs a DNS Get Host asynchronously

        .PARAMETER Computername
            List of computers to check Get Host against

        .NOTES
            Name: Get-DNSHostEntryAsync
            Author: Boe Prox
            Version History:
                1.0 //Boe Prox - 12/24/2015
                    - Initial result

        .OUTPUT
            Net.AsyncGetHostResult

        .EXAMPLE
            Get-DNSHostEntryAsync -Computername google.com,prox-hyperv,bing.com, github.com, powershellgallery.com, powershell.org

            Computername          Result
            ------------          ------
            google.com            216.58.218.142
            prox-hyperv           192.168.1.116
            bing.com              204.79.197.200
            github.com            192.30.252.121
            powershellgallery.com 191.234.42.116
            powershell.org        {104.28.15.25, 104.28.14.25}

        .EXAMPLE
            Get-DNSHostEntryAsync -Computername 216.58.218.142

            Computername   Result
            ------------   ------
            216.58.218.142 dfw25s08-in-f142.1e100.net
    #>
    #Requires -Version 3.0
    [OutputType('Net.AsyncGetHostResult')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True)]
        [string[]]$Computername
    )
    Begin {
        $Computerlist = New-Object System.Collections.ArrayList
        If ($PSBoundParameters.ContainsKey('Computername')) {
            [void]$Computerlist.AddRange($Computername)
        } Else {
            $IsPipeline = $True
        }
    }
    Process {
        If ($IsPipeline) {
            [void]$Computerlist.Add($Computername)
        }
    }
    End {
        $Task = ForEach ($Computer in $Computername) {
            If (([bool]($Computer -as [ipaddress]))) {
                [pscustomobject] @{
                    Computername = $Computer                    
                    Task = [system.net.dns]::GetHostEntryAsync($Computer)
                }                 
            } Else {
                [pscustomobject] @{
                    Computername = $Computer                    
                    Task = [system.net.dns]::GetHostAddressesAsync($Computer)
                }                
            }
        }        
        Try {
            [void][Threading.Tasks.Task]::WaitAll($Task.Task)
        } Catch {}
        $Task | ForEach {
            $Result = If ($_.Task.IsFaulted) {
                $_.Task.Exception.InnerException.Message
            } Else {
                If ($_.Task.Result.IPAddressToString) {
                    $_.Task.Result.IPAddressToString
                } Else {
                    $_.Task.Result.HostName
                }
            }
            $Object = [pscustomobject]@{
                Computername = $_.Computername
                Result = $Result
            }
            $Object.pstypenames.insert(0,'Net.AsyncGetHostResult')
            $Object
        }
    }

}
