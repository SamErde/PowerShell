<#
    .SYNOPSIS
    Copy the user's primary email address from the proxyAddresses attribute to the email address attribute on their AD Account.

    .NOTES

    This is an old script that I found. There is a better, easier way to do this now!

#>

<# Simple Version
    $users = Get-ADUser -Filter * -Properties mail,emailaddress,proxyAddresses
    foreach ($user in $users) {
        $addresses = $user | Select -ExpandProperty ProxyAddresses
        $emailaddress = ($addresses | ? {$_ -clike "SMTP:*"}).TrimStart("SMTP:") #Find the primary address with an all-caps SMTP prefix
        Set-ADUser $user -EmailAddress $emailaddress -Whatif #Put the email address back in!
    }
    # The fun version follows!
#>


$MainScriptActivity = "Setting users' emailaddress from their primary STMP in proxyAddresses"
$UserLoopActivity = "Looping through $userCount user accounts"

Write-Progress -Id 1 -Activity $MainScriptActivity -Status "Getting all Active Directory user objects that have a value in their proxyAddresses attribute" -PercentComplete 1
$users = Get-ADUser -Filter * -Properties mail,emailaddress,proxyAddresses | Sort-Object Name
$userCount = $users.Count
$MainScriptStatus = "Processing $userCount users"
$i = 0

Write-Progress -Id 1 -Activity $MainScriptActivity -Status $MainScriptStatus -PercentComplete 5
foreach ($user in $users)
{
    $i++
    Write-Progress -Id 2 -Activity $UserLoopActivity -Status "$i of $userCount - $user.Name" -PercentComplete ($i / $userCount * 100) -ParentId 1

    $addresses = $user | Select-Object -ExpandProperty ProxyAddresses
    If ($addresses)
        {
            $emailaddress = ($addresses | Where-Object {$_ -clike "SMTP:*"}).TrimStart("SMTP:")
            Set-ADUser $user -EmailAddress $emailaddress -Confirm:$false
            Write-Progress -Id 1 -Activity $MainScriptActivity -Status $MainScriptStatus -PercentComplete ((($i / $userCount * 100) * 0.95) + 5)
        }
    Else
        {
            Write-Output "No proxyAddresses found for $user."
            Write-Progress -Id 1 -Activity $MainScriptActivity -Status $MainScriptStatus -PercentComplete ((($i / $userCount * 100) * 0.95) + 5)
        }
}
Write-Progress -Id 2 -Activity $UserLoopActivity -Status "Finished processing the list of users" -ParentId 1
Write-Progress -Id 1 -Activity $MainScriptActivity -Status "Task Complete"
