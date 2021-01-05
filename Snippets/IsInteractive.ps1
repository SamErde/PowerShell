# Check if the user is working interactively in the shell versus running a pre-written script or function.
# Discuss: A function could be run interactively or non-interactively, so it may be worth treating that differently.
Function IsInteractive {
    if ( ($myInvocation.InvocationName.Length -eq 0) -and ($myInvocation.PositionMessage.Length -eq 0) ) { 
        Write-Output "Interactive. Can prompt user for input." 
    } 
    else { 
        Write-Output "Non-Interactive. Will not prompt user for input. Report error or log checkpoint instead." 
    }
}
