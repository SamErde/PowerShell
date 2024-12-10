$Token = (Get-ADGroup 'Domain Users' -Properties PrimaryGroupToken).PrimaryGroupToken

Get-ADUser -Filter 'Enabled -eq "False"' -Properties PrimaryGroup, MemberOf | ForEach-Object {

    # If the user's Primary Group is not Domain Users, then set Domain Users as their Primary Group.
    If ($_.PrimaryGroup -notmatch 'Domain Users') {
        Set-ADUsers -Identity $_ -Replace @{PrimaryGroupID = $Token } -Verbose
    }

    # If User is a member of more than 1 Group, remove all group memberships except Domain Users.
    If ($_.memberof) {
        $Group = Get-ADPrincipalGroupMembership -Identity $_ | Where-Object { $_.Name -ne 'Domain Users' }
        Remove-ADPrincipalGroupMembership -Identity $_ -MemberOf $Group -Confirm:$false -Verbose
    }

    # Move User to Disabled OU.
    #Move-ADObject -Identity $_ -TargetPath "OU=Disabled Users,OU=Disabled Accounts," -Verbose

} #Foreach
