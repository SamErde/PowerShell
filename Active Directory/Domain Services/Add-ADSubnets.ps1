#* FileName: Add-Subnets.ps1
#*=============================================================================
#* Script Name: Add Subnets
#* Created: [11/31/2010]
#* Author: Jerry Martin
#* Company: The Home Depot
#* Email: Jerry_Martin@homedepot.com
#* Web: http://www.homedepot.com
#* Powershell Version: 2.0
#* Reqrmnts: Microsoft Active Directory Module
#* Keywords:
#*=============================================================================
#* Purpose:  This script was created to import a list of subnets from a CSV
#* File into Active Directory, Directory Services Site and Services Module.
#* This automates the process of creating Subnets and is intended to be used
#* in conjuction with the Add-SiteLinks, Add-Sites and Get-SitesAndServices
#* Scripts.
#*=============================================================================

#*=============================================================================
#* Usage.
#*=============================================================================
#* The parameters for this script are
#*        -InputCSV "Path to CSV File" Default is ".\Subnets.csv"
#*        -LogFile "Path to Log File" Default is ".\Logfile.txt"
#*        -NewLog Y/N  Defaults to N, enter Y to create a new log file
#*
#* Typical Usage would look like the following...
#* .\Add-Subnets.ps1 -InputCSV .\Subnetlist2.csv -Logfile C:\Logfile.txt
#*   OR
#* .\Add-Subnets.ps1
#* Without using the Parameters the script will use the default file locations
#* for the Input CSV file and Log File, and will append to the existing log.
#*=============================================================================

#*=============================================================================
#* Creation Resources and Code Samples
#*=============================================================================
#* HOW TO CREATE A FUNCTION TO VALIDATE THE EXISTENCE OF AN AD OBJECT (Test-XADObject)
#* http://blogs.msdn.com/b/adpowershell/archive/2009/05/05/how-to-create-a-function-to-validate-the-existence-of-an-ad-object-test-xadobject.aspx
#*=============================================================================

#*=============================================================================
#* The Script
#*=============================================================================
#Get input from cmd line for Log file location and Input CSV file locations if
#They differ from the defaults.
Param (
    [Parameter()][string]$InputCSV = '.\Subnets.csv',
    [Parameter()][String]$Logfile = '.\Logfile.txt',
    [Parameter()][String]$NewLog = 'N')

#Set the Script to continue on errors.
$ErrorActionPreference = 'silentlycontinue'

#Clear the cmd window
Clear-Host

#Verify PowerShell Version 2
if ($Host.Version.Major -lt 2)
{ Write-Host 'Wrong Version of Powershell, Exiting now...'; Start-Sleep5 ; Exit }

#Verfiy the path to the Input CSV file
if (!(Test-Path $InputCSV))
{ Write-Host 'Your Input CSV does not exist, Exiting...' ; Start-Sleep5 ; Exit }

#Check for the existance of the Active Directory Module
If (!(Get-Module -ListAvailable | Where-Object { $_.name -eq 'ActiveDirectory' }))
{ Write-Host 'The Active Directory module is not installed on this system.' ; Start-Sleep5 ; exit }

#Import the Active Directory Module
Import-Module ActiveDirectory

#List the Current Domain that the script is using.
Write-Host "The current Domain Contoller is $((Get-ADDomainController).HostName)" -BackgroundColor Yellow -ForegroundColor Black

If ($NewLog -eq 'Y') {
    Write-Host 'Creating a new log file'
    #Rename Existing file to old.
    Get-Item $Logfile | Move-Item -Force -Destination { [IO.Path]::ChangeExtension( $_.Name, 'old' ) }
}

#Add the Current Date to the log file
$Date = Get-Date
Add-Content $Logfile $Date

#Import the SubnetList CSV file.
# Please note,
# We are using the first line of the file to set the property names of the items
# imported, so the csv file should have the following as the first line.
#   subnetname,sitename,subnetlocation,subnetdescription
#
# Then the contents should look something like this.
#   10.25.0.0/24,ST9990,"Store 9990","Test Subnet 0"
$SBin = Import-Csv $InputCSV


# Get the Subnet container
$ConfigurationDN = (Get-ADRootDSE).ConfigurationNamingContext
$SubnetDN = ('CN=Subnets,CN=Sites,' + $ConfigurationDN)

#Create the funtion to test existance of the subnets for error checking.
#See Creation Resources and Code Samples Section to be linked for more info.
function Test-XADObject() {
    [CmdletBinding(ConfirmImpact = 'Low')]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = 'Identity of the AD object to verify if exists or not.')]
        [Object] $Identity
    )

    trap [Exception] {
        return $false
    }
    $auxObject = Get-ADObject -Identity $Identity
    return ($Null -ne $auxObject)
}

#Create the funtion to test existance of the sites for error checking.
# See Creation Resources and Code Samples Section to be linked for more info.
function Test-XADSite() {
    [CmdletBinding(ConfirmImpact = 'Low')]
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = 'Identity of the AD object to verify if exists or not.')]
        [Object] $Identity
    )

    trap [Exception] {
        return $false
    }
    $auxObject = Get-ADObject -Filter 'ObjectClass -eq "site"' -SearchBase $ConfigurationDN | Where-Object { $_.Name -eq $Identity }
    return ($Null -ne $auxObject)
}

#null out i
$i = $null

#Loop through each line in the CSV file and create the subnets based on info in the CSV.
foreach ($SB in $SBin) {
    #Incriment i for each object in the csv file
    $i++
    # Create the new subnet container name
    $NewSubnetDN = ('CN=' + $SB.subnetname + ',' + $SubnetDN)


    If (!(Test-XADSite -Identity $SB.Sitename)) {
        Write-Host "Site $($SB.Sitename) Does Not Exist, Please create Sites before Subnets." -BackgroundColor Red -ForegroundColor White
    } Else {
        #Test if the new subnet doesn't already exist
        If (!(Test-XADObject -Identity $newSubnetDN)) {

            #Creating the new subnet
            $for = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $fortyp = [System.DirectoryServices.ActiveDirectory.DirectoryContexttype]'forest'
            $forcntxt = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext($fortyp, $for)

            $subnet = New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectorySubnet($forcntxt, $SB.subnetname, $SB.sitename)
            $Subnet.Location = $SB.subnetlocation
            $subnet.Save()

            #Set the Subnet Description
            $subnetde = $subnet.GetDirectoryEntry()
            $subnetde.Description = $SB.subnetdescription
            $subnetde.CommitChanges()

            #Verify that the subnet was created sucessfully and update the log
            If (Test-XADObject -Identity $newSubnetDN) {
                #Update the console
                Write-Host "Created & Verified Subnet: $($SB.subnetname)"
                #Update the log file
                Add-Content -Path $Logfile -Value "$($SB.subnetname),Created and Verified"
            }

            #Log that we Attempted to create the subnet but could not verify it.
            Else {
                #Update the Console
                Write-Host "Created but not Verified Subnet: $($SB.subnetname)"
                #Update the log file
                Add-Content -Path $Logfile -Value "$($SB.subnetname),Created but not Verified "
            }


        }
        #Make note that the subnet already existed.
        Else {
            #Update the Console
            Write-Host "Subnet $($SB.subnetname) already exists. Skipping this subnet" -BackgroundColor Red -ForegroundColor White
            #Update the log file.
            Add-Content -Path $Logfile -Value "$($SB.subnetname),PreExisting"
        }
    }
    #Give a graphical representation of the percentage of work completed.
    Write-Progress -Activity 'Adding Subnets...' -Status 'Percent added: ' -PercentComplete (($i / $SBin.length) * 100)

}

#*=============================================================================
#* End of The Script
#*=============================================================================
