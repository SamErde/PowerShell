function Copy-FileToVMwareGuest {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $vCenterServer,
        [Parameter()]
        [string]
        $GuestVM,
        [Parameter()]
        [string]
        $SourcePath,
        [Parameter()]
        [string]
        $DestinationPath = 'C:\Temp'
    )
    Import-Module VMware.PowerCLI
    $Null = Set-PowerCLIConfiguration -InvalidCertificateAction Prompt -DefaultVIServerMode Multiple -Confirm:$False -Scope Session
    Connect-VIServer -Server $vCenterServer -Credential (Get-Credential -Message 'Enter credentials for vCenter.')

    $GuestCredential = (Get-Credential -Message 'Enter administrative credentials for the guest VM.')

    try {
        Copy-VMGuestFile -LocalToGuest -Source $SourcePath -Destination $DestinationPath -VM $GuestVM -GuestCredential $GuestCredential -Force
    } catch {
        $Error
    }
}
