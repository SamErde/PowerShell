<#
.SYNOPSIS

.DESCRIPTION

.NOTES

#>

#Update this list of servers or replace the statically generated array with a Get-ExchangeServer or Get-ADDomainController type of cmdlet.
$servers = @('', '', '')
$Creds = Get-Credential

if ($session) { Remove-PSSession $session }

#Loop through each server in the list, open a PowerShell remoting session, then show the name and status of the session. Skip (continue) to the next server if a connection fails.
foreach ($server in $servers) {
    $session = $null

    Try {
        Write-Information "Connecting to $server... " -InformationAction Continue
        $session = New-PSSession -ComputerName $server -Name $server -Credential $Creds -ErrorAction Stop
        # Enter-PSSession is interactive-only; use Invoke-Command to run code in the remote session.
        Invoke-Command -Session $session -ErrorAction Stop -ScriptBlock {
            <#
                Code to be run on each remote server goes here.
            #>
            Write-Information 'Inner code.' -InformationAction Continue
        }
    } Catch {
        Write-Warning "Failed to create or use the PSSession for $server. Skipping." -WarningAction Continue
        Continue
    } Finally {
        if ($session) {
            # Cleanup and then show the current PSSession state.
            Remove-PSSession $session -ErrorAction SilentlyContinue
            Write-Information "$($session.ComputerName) $($session.State) `n`n" -InformationAction Continue
        }
    }
}
