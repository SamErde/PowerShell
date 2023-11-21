function Get-AverageExecutionTime {
    <#
    .SYNOPSIS
        Get the average execution time for running a script block multiple times.

    .DESCRIPTION
        Get the average time that it takes to execute a scriptblock. By default, the script block is run 50 times.

    .NOTES


    .EXAMPLE
        [scriptblock]$Scriptblock = { $TypeAccellerators = [System.Management.Automation.PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get | Sort-Object }
        Get-AvgExecutionTime $Scriptblock

    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify a scriptblock to measure the execution time of."
        )]
            [scriptblock]$Scriptblock,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the number of times to run the scriptblock. (Default 50)"
        )]
            [int]$Count = 50
    )

    begin {
        [timespan]$TotalTime = New-TimeSpan
    }

    process {
        # Run the command $Count times
        for ($i = 0; $i -lt $Count; $i++) {
            # Get the current time before execution
            $StartTime = Get-Date

            # Execute the command
            $Scriptblock | Invoke-Expression

            # Get the current time after execution
            $EndTime = Get-Date

            $RunTime = New-TimeSpan -Start $StartTime -End $EndTime
            Write-Verbose "The total runtime for run $($i + 1) was $($RunTime.TotalMilliseconds)."

            # Calculate the execution time and add it to the total time
            $TotalTime = $TotalTime.Add($RunTime)
        }

        # Calculate the average execution time
        $AverageTime = $($TotalTime.Milliseconds) / $Count
    }

    end {
        Write-Verbose "The average execution time for your scriptblock was $($AverageTime.Milliseconds) ms."
        Return $AverageTime
    }
}




function Get-AverageExecutionTime2 {
    <#
    .SYNOPSIS
        Get the average execution time for running a script block multiple times.

    .DESCRIPTION
        Get the average time that it takes to execute a scriptblock. By default, the script block is run 50 times.

    .NOTES


    .EXAMPLE
        [scriptblock]$Scriptblock = { $TypeAccellerators = [System.Management.Automation.PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get | Sort-Object }
        Get-AvgExecutionTime $Scriptblock

    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$true,
            HelpMessage="Specify a scriptblock to measure the execution time of."
        )]
            [scriptblock]$Scriptblock,

        [Parameter(
            Mandatory=$false,
            HelpMessage="Specify the number of times to run the scriptblock. (Default 50)"
        )]
            [int]$Count = 50
    )

    begin {
        [timespan]$TotalTime = New-TimeSpan
    }

    process {
        # Run the command $Count times
        for ($i = 0; $i -lt $Count; $i++) {
            $RunTime = Measure-Command -Expression { $Scriptblock | Invoke-Expression }

            $TotalTime = $TotalTime + $RunTime
            Write-Verbose "The total runtime for run $($i + 1) was $($RunTime.Milliseconds) ms."

            # Calculate the execution time and add it to the total time
            $TotalTime
        }

        # Calculate the average execution time
        $AverageTime = $($TotalTime.TotalMilliseconds) / $Count
    }

    end {
        Write-Verbose "The average execution time for your scriptblock was $($AverageTime.Milliseconds) ms."
        Return $AverageTime
    }
}
