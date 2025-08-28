function Get-LockedOutLocation {
    <#
.SYNOPSIS
    This function will locate the computer that processed a failed user logon attempt which caused the user account to become locked out.

.DESCRIPTION
    This function will locate the computer that processed a failed user logon attempt which caused the user account to become locked out.
    The locked out location is found by querying the PDC Emulator for locked out events (4740).
    The function will display the BadPasswordTime attribute on all of the domain controllers to add in further troubleshooting.

.EXAMPLE
    PS C:\>Get-LockedOutLocation -Identity Joe.Davis


    This example will find the locked out location for Joe Davis.
.NOTE
    This function is only compatible with an environment where the domain controller with the PDCe role to be running Windows Server 2008 SP2 and up.
    The script is also dependent the ActiveDirectory PowerShell module, which requires the AD Web services to be running on at least one domain controller.
    Author:Jason Walker
    Last Modified: 3/20/2013
#>
    [CmdletBinding()]

    param(
        [Parameter(Mandatory = $True)]
        [String]$Identity
    )

    begin {
        $DCCounter = 0
        $LockedOutStats = @()

        try {
            Import-Module ActiveDirectory -ErrorAction Stop
        } catch {
            Write-Warning $_
            break
        }
    }#end begin
    process {

        #Get all domain controllers in domain
        $DomainControllers = Get-ADDomainController -Filter *
        $PDCEmulator = ($DomainControllers | Where-Object { $_.OperationMasterRoles -contains 'PDCEmulator' })

        Write-Verbose 'Finding the domain controllers in the domain'
        foreach ($DC in $DomainControllers) {
            $DCCounter++
            Write-Progress -Activity 'Contacting DCs for lockout info' -Status "Querying $($DC.Hostname)" -PercentComplete (($DCCounter / $DomainControllers.Count) * 100)
            try {
                $UserInfo = Get-ADUser -Identity $Identity -Server $DC.Hostname -Properties AccountLockoutTime, LastBadPasswordAttempt, BadPwdCount, LockedOut -ErrorAction Stop
            } catch {
                Write-Warning $_
                continue
            }
            if ($UserInfo.LastBadPasswordAttempt) {
                $LockedOutStats += New-Object -TypeName PSObject -Property @{
                    Name                   = $UserInfo.SamAccountName
                    SID                    = $UserInfo.SID.Value
                    LockedOut              = $UserInfo.LockedOut
                    BadPwdCount            = $UserInfo.BadPwdCount
                    BadPasswordTime        = $UserInfo.BadPasswordTime
                    DomainController       = $DC.Hostname
                    AccountLockoutTime     = $UserInfo.AccountLockoutTime
                    LastBadPasswordAttempt = ($UserInfo.LastBadPasswordAttempt).ToLocalTime()
                }
            }#end if
        }#end foreach DCs
        $LockedOutStats | Format-Table -Property Name, LockedOut, DomainController, BadPwdCount, AccountLockoutTime, LastBadPasswordAttempt -AutoSize

        #Get User Info
        try {
            Write-Verbose "Querying event log on $($PDCEmulator.HostName)"
            $LockedOutEvents = Get-WinEvent -ComputerName $PDCEmulator.HostName -FilterHashtable @{LogName = 'Security'; Id = 4740 } -ErrorAction Stop | Sort-Object -Property TimeCreated -Descending
        } catch {
            Write-Warning $_
            continue
        }#end catch

        foreach ($item in $LockedOutEvents) {
            if ($item | Where-Object { $_.Properties[2].value -match $UserInfo.SID.Value }) {

                $item | Select-Object -Property @(
                    @{Label = 'User'; Expression = { $_.Properties[0].Value } }
                    @{Label = 'DomainController'; Expression = { $_.MachineName } }
                    @{Label = 'EventId'; Expression = { $_.Id } }
                    @{Label = 'LockedOutTimeStamp'; Expression = { $_.TimeCreated } }
                    @{Label = 'Message'; Expression = { $_.Message -split "`r" | Select-Object -First 1 } }
                    @{Label = 'LockedOutLocation'; Expression = { $_.Properties[1].Value } }
                )

            }#end if event

        }#end foreach lockout event

    }#end process

}#end function
