$user = Read-Host -Prompt 'Enter the username of the mailbox that you are granting access to'
$newuser = Read-Host -Prompt 'Enter the username of the user gaining access'


ForEach ($folder in (Get-MailboxFolderStatistics -identity $user)) {

    $foldername = "$user" + $folder.identity.replace('\', ':\')

    Add-MailboxFolderPermission $foldername -User $newuser -AccessRights $ar

}
