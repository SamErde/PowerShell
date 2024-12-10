Get-ADComputer -SearchBase 'OU=Member Servers,DC=DOMAINNAME,DC=org' `
    -Properties Name, ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime -Filter { Name -notlike '*xen*' } | `
        Select-Object Name, ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime | Sort-Object Name | Out-GridView
