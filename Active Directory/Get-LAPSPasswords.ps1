Get-adcomputer -SearchBase "OU=Member Servers,DC=DOMAINNAME,DC=org" `
    -Properties Name,ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime -Filter {Name -notlike "*xen*"} | `
    Select Name,ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime | Sort Name | Out-GridView