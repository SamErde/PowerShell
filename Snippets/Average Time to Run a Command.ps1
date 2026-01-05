function Get-AverageExecutionTime {
    <#
    .SYNOPSIS
        Get the average execution time for running a script block multiple times.

    .DESCRIPTION
        Get the average time that it takes to execute a scriptblock. By default, the script block is run 50 times.

    .NOTES
        Author: Sam Erde
        Version: 1.1
        Date: 2026-01-05

    .EXAMPLE
        [scriptblock]$Scriptblock = { $TypeAccelerators = [System.Management.Automation.PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get | Sort-Object }
        Get-AverageExecutionTime $Scriptblock

    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Specify a scriptblock to measure the execution time of.'
        )]
        [scriptblock]$Scriptblock,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Specify the number of times to run the scriptblock. (Default 50)'
        )]
        [int]$Count = 50
    )

    begin {
        [timespan]$TotalTime = New-TimeSpan
    }

    process {
        # Run the command $Count times
        for ($i = 0; $i -lt $Count; $i++) {
            # Measure the execution time
            $RunTime = Measure-Command -Expression { $Scriptblock.Invoke() }

            Write-Verbose "The total runtime for run $($i + 1) was $($RunTime.TotalMilliseconds) ms."

            # Add the execution time to the total time
            $TotalTime = $TotalTime.Add($RunTime)
        }

        # Calculate the average execution time in milliseconds
        $AverageTime = $TotalTime.TotalMilliseconds / $Count
    }

    end {
        Write-Verbose "The average execution time for your scriptblock was $AverageTime ms."
        return $AverageTime
    }
}
