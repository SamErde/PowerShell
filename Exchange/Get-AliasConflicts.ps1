function Get-AliasConflicts {
    <#
    .SYNOPSIS
        Get all conflicting recipient aliases in Exchange.
    .DESCRIPTION
        Get all instances of name conflicts where multiple Exchange recipients have the same alias.
    .NOTES
        Author: Sam Erde
        Modified: 2024-06-18
        Version: 0.0.3
#>
    [CmdletBinding()]
    [OutputType([Microsoft.Exchange.Data.Directory.Management.ReducedRecipient], [Microsoft.PowerShell.Commands.GroupInfo])]
    param (
        # Optionally specify the Resultsize parameter as an integer or 'Unlimited'
        [ValidatePattern('^(\d+|Unlimited)$')]
        $Resultsize = 'Unlimited',

        # Optionally copy the results to the clipboard as a CSV
        [switch]
        $Clip
    )

    Write-Information "Checking $Resultsize recipients..."
    $Recipients = Get-Recipient -Resultsize $Resultsize -SortBy alias
    $OverlappingAliases = $Recipients | Group-Object -Property alias | Where-Object { $_.Count -gt 1 }

    # Replace domainName.tld below. This replace statement is simply used to add commas between recipient IDs.
    $AliasConflicts = $OverlappingAliases |
        Select-Object Count,
        @{Name = 'Alias'; Expression = { $_.Name } },
        @{Name = 'ConflictedRecipients'; Expression = { [string]($_.Group) -Replace ' domainName.tld/', ', domainName.tld/' } }

    if ($Clip) {
        $AliasConflicts | ConvertTo-Csv -NoTypeInformation -Delimiter ';' | Set-Clipboard
    }

    $AliasConflicts
}
