function Get-MailboxDatabaseSize {
    [CmdletBinding()]
    [Alias('Get-DatabaseSize')]
    param ()
    
    Get-MailboxDatabase -Status | Sort-Object Name | `
        Select-Object Name,
        @{Name='DB Size (Gb)';Expression={$_.DatabaseSize.ToGb()}},
        @{Name='DB Free Whitespace (Gb)';Expression={$_.AvailableNewMailboxSpace.ToGb()}}
}
