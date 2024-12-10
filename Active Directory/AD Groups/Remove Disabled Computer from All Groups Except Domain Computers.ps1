$Token = (Get-ADGroup 'Domain Computers' -Properties PrimaryGroupToken).PrimaryGroupToken

Get-ADComputer -Filter 'Enabled -eq "False"' -SearchBase 'OU=Disabled Computers,...' -Properties PrimaryGroup, MemberOf | ForEach-Object {

    #If Computer Primary Group is not Domain Computers, then Set Domain Computers as Primary Group.
    If ($_.PrimaryGroup -notmatch 'Domain Computers') {
        Set-ADComputer -Identity $_ -Replace @{PrimaryGroupID = $Token } -Verbose
    } #If

    #If Computer is a member of more than 1 Group. Remove All Group except Domain Computers.
    If ($_.memberof) {
        $Group = Get-ADPrincipalGroupMembership -Identity $_ | Where-Object { $_.Name -ne 'Domain Computers' }
        Remove-ADPrincipalGroupMembership -Identity $_ -MemberOf $Group -Confirm:$false -Verbose
    } #If

    #Move Computer to Disabled OU.
    #Move-ADObject -Identity $_ -TargetPath "OU=Disabled Computers,OU=Disabled Accounts,DC=DOMAINNAME,DC=org" -Verbose

} #Foreach
