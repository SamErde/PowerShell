$mbxs = Get-Mailbox "Sam Erde" #-Resultsize 10
foreach ($mbx in $mbxs) {
    $mbxconfig = Get-MailboxJunkEmailConfiguration $mbx
    $mbxconfig.TrustedSendersAndDomains
    write-output " `n"
    $mbxconfig.TrustedSendersAndDomains += "",""
    Set-MailboxJunkEmailConfiguration -Identity $mbx -TrustedSendersAndDomains $mbxConfig.TrustedSendersAndDomains #-BlockedSendersAndDomains $mbxconfig.BlockedSendersAndDomains
}
