function Show-ExampleProgressUpdates {
    # When looping through a large number of objects, show periodic progress updates with a stopwatch
    begin {
        $StopWatchSegment = New-Object System.Diagnostics.Stopwatch
        $StopWatchSegment.Start()
        $StopWatchTotal = New-Object System.Diagnostics.Stopwatch
        $StopWatchTotal.Start()
        Write-Output "Started processing!"
    }
    process {

        foreach ($object in 1..100) {
            $ProcessedCount++
            if ($ProcessedCount % 10 -eq 0) {
                Write-Output "`t $ProcessedCount objects processed."
                Start-Sleep -Seconds 1
            }

            if ($StopWatchSegment.Elapsed.TotalSeconds -gt 5) {
                Write-Output "Processed $ProcessedCount objects in $($StopWatchSegment.Elapsed.TotalSeconds) seconds. (Total: $($StopWatchTotal.Elapsed.TotalSeconds) seconds)."
                $StopWatchSegment.Restart()
            }
        }

    }
    end {
        $StopWatchSegment.Stop()
        $StopWatchTotal.Stop()
        Remove-Variable StopWatchSegment, StopWatchTotal
    }
}
