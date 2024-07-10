# Hybrid: The ACLableSyncedObjectEnabled parameter specifies whether remote mailboxes in hybrid environments are stamped as ACLableSyncedMailboxUser.
Set-OrganizationConfig -ACLableSyncedObjectEnabled $True

# EXO: Turn off focused inbox
Set-OrganizationConfig -FocusedInboxOn $false

# EXO: Enable unified audit log
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
Get-AdminAuditLogConfig | Format-List UnifiedAuditLogIngestionEnabled
