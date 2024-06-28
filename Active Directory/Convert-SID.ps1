Function Resolve-SID {
<#
.NOTES
    By Jeff Hicks
    https://jdhitsolutions.com/blog/powershell/8947/i-sid-you-not/
#>
    [cmdletbinding()]
    [OutputType("ResolvedSID", "String")]
    Param(
        [Parameter(
            Position = 0,
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            HelpMessage = "Enter a SID string."
        )]
        [ValidateScript({
            If ($_ -match 'S-1-[1235]-\d{1,2}(-\d+)*') {
                $True
            }
            else {
                Throw "The parameter value does not match the pattern for a valid SID."
                $False
            }
        })]
        [string]$SID,
        [Parameter(HelpMessage = "Display the resolved account name as a string.")]
        [switch]$ToString
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"
    } #begin

    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] Converting $SID "
        Try {
            if ($SID -eq 'S-1-5-32') {
                #apparently you can't resolve the builtin account
                $resolved = "$env:COMPUTERNAME\BUILTIN"
            }
            else {
                $resolved = [System.Security.Principal.SecurityIdentifier]::new($sid).Translate([system.security.principal.NTAccount]).value
            }

            if ($ToString) {
                $resolved
            }
            else {
                if ($resolved -match "\\") {
                    $domain = $resolved.Split("\")[0]
                    $username = $resolved.Split("\")[1]
                }
                else {
                    $domain = $Null
                    $username = $resolved
                }
                [pscustomObject]@{
                    PSTypename = "ResolvedSID"
                    NTAccount  = $resolved
                    Domain     = $domain
                    Username   = $username
                    SID        = $SID
                }
            }
        }
        Catch {
            Write-Warning "Failed to resolve $SID. $($_.Exception.InnerException.Message)"
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"
    } #end

} #close Resolve-SID
