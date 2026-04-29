# Create group managed service accounts with this one easy step! Administrators will hate you!
# Takes two command line parameters, gmsa and servers
# gmsa should be the name of the MSA - "msa.example"
# servers should be the list of servers that will have access to use the MSA, in a comma-seperated list - dinfserver01,dinfserver02,dinfserver03
#

Function New-gMSA {
    <#
    .SYNOPSIS
        Creates a group managed service account and retrieval group.

    .DESCRIPTION
        Creates the Active Directory group that can retrieve a gMSA password, adds the target servers, and creates the
        gMSA with caller-provided domain and distinguished name paths.

    .PARAMETER gMSA
        The gMSA name. gMSA names must be 15 characters or fewer.

    .PARAMETER Servers
        Computer account names that can retrieve the managed password.

    .PARAMETER Credential
        Credential used for Active Directory operations.

    .PARAMETER DomainDnsName
        DNS domain suffix for the gMSA DNS host name.

    .PARAMETER GroupPath
        Distinguished name of the OU where the retrieval group should be created.

    .PARAMETER ServiceAccountPath
        Distinguished name of the container where the gMSA should be created.

    .EXAMPLE
        New-gMSA -gMSA 'appsvc01' -Servers 'SERVER01','SERVER02' -Credential (Get-Credential) -DomainDnsName 'example.com' -GroupPath 'OU=gMSA Groups,DC=example,DC=com' -ServiceAccountPath 'CN=Managed Service Accounts,DC=example,DC=com'

    .OUTPUTS
        None
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,15)]
        [string]$gMSA,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Servers,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainDnsName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServiceAccountPath
    )

    Import-Module ActiveDirectory
    $Group = "MSA " + $gMSA
    $DNS = "$gMSA.$DomainDnsName"
    New-ADGroup -Name $Group -GroupScope Global -DisplayName $Group -Description "Permission group for $gMSA" -Path $GroupPath -Credential $Credential
    Add-ADGroupMember -Identity $Group -Members ($Servers | ForEach-Object {Get-ADComputer -Identity $_ -Credential $Credential}) -Credential $Credential
    New-ADServiceAccount -Name $gMSA -DNSHostName $DNS -PrincipalsAllowedToRetrieveManagedPassword $Group -Path $ServiceAccountPath -Credential $Credential
}
