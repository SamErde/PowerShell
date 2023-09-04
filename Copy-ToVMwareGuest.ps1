# This is old. Need to review!

Import-Module VMware.PowerCLI
$Null = Set-PowerCLIConfiguration -InvalidCertificateAction Prompt -DefaultVIServerMode Multiple -Confirm:$False -Scope Session
Connect-VIServer -Server "VC_SERVER1","VC_SERVER2IFNEEDED"] -Credential (Get-Credential -Message "Enter credentials for vCenter.")

$SourcePath = "" # Source folder or filename
$GuestVM = "" # Target VM name as it appears in vCenter
$GuestCredential = (Get-Credential -Message "Enter administrative credentials for the guest VM.") # Admin creentials on the guest VM
$DestinationPath = "C:\Temp" # Destination path on the target VM

Copy-VMGuestFile -LocalToGuest -Source $SourcePath -Destination $DestinationPath -VM $GuestVM -GuestCredential $GuestCredential -Force 