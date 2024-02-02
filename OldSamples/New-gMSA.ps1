# Create group managed service accounts with this one easy step! Administrators will hate you!
# Takes two command line parameters, gmsa and servers
# gmsa should be the name of the MSA - "msa.example"
# servers should be the list of servers that will have access to use the MSA, in a comma-seperated list - dinfserver01,dinfserver02,dinfserver03
#

Function New-gMSA {
    param (
        [Parameter(Mandatory=$true)][string]$gMSA,
        [Parameter(Mandatory=$true)][array]$Servers,
        [Parameter(Mandatory=$true)][System.Management.Automation.PSCredential]$Credential
    )
    If ($gMSA.Length -gt 15) {
        Write-Output "gMSA name too long. 15 character maximum."
        Exit
    }
    Import-Module ActiveDirectory
    $Group = "MSA " + $gMSA
    $DNS = $gMSA + ".DOMAIN.org"
    New-ADGroup -Name $Group -GroupScope Global -DisplayName $Group -Description "Permission group for $gMSA" -Path "OU=gMSA Password Retrieval Groups,OU=Security Groups,DC=DOMAINNAME,DC=org" -Credential $Credential
    Add-ADGroupMember -Identity $Group -Members ($Servers | ForEach-Object {Get-ADComputer $_}) -Credential $Credential
    New-ADServiceAccount -Name $gMSA -DNSHostName $DNS -PrincipalsAllowedToRetrieveManagedPassword $Group -Path "CN=Managed Service Accounts,DC=DOMAINNAME,DC=org" -Credential $Credential
}
