# WORKING DRAFT - Don't save your access key here in plain text.

# Install Defender for Identity Sensor (works on Windows Server Core). Install logs are at %AppData%\Local\Temp.
$AccessKey = ''
.\"Azure ATP sensor Setup.exe" /quiet NetFrameworkCommandLineArguments="/q" AccessKey=$AccessKey

<# Review notes and script the creation of gMSAs and/or service accounts, and give credit:
  https://dirteam.com/sander/2022/03/23/howto-programmatically-add-a-microsoft-defender-for-identity-action-account-to-active-directory/
#>

<#
 - Verify the machine has connectivity to the relevant Defender for Identity cloud service endpoint(s). https://learn.microsoft.com/en-us/defender-for-identity/configure-proxy#enable-access-to-defender-for-identity-service-urls-in-the-proxy-server
 - Extract the installation files from the zip file. Installing directly from the zip file will fail.
 - Run Azure ATP sensor setup.exe with elevated privileges (Run as administrator) and follow the setup wizard.
 - Install KB 3047154 for Windows Server 2012 R2 only.
#>
