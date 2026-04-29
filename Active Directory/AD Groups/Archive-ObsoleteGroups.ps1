# ============================================================
# 	Script Information
#
#	Title:			Obsolete AD Group Archiver
#	Author:			Sam Erde
#
#	Created:		11/04/2014
#	Description:	Read a list of obsolete groups from a text file, export the members to a separate text file for each group,
#                   and then empty the obsolete groups. They can be deleted after a week or two to prove they are no longer used.
#                   The empty groups are also moved to the "Obsolete Groups" OU.
#
#                   DO NOT RUN TWICE ON THE SAME FILE OR THE ARCHIVE WILL BE OVERWRITTEN!
#
#   To Do:
#                   Add error handling
#                   Prompt for a job name at each run so their is a separate archive folder for each job to help prevent an archive from being overwritten.
#                   Add handling of group names to it can discover DNs if needed. This may require a specific format within the input file, such as group DNs there.
#
# ============================================================

# TODO: This script requires customization before running. The $Domain, archive paths,
# TODO: group identity/OU values in the loop, and Move-ADObject target path must all be set
# TODO: for your environment. See inline TODO comments below.
param (
    # The Active Directory domain controller or domain name to run against.
    [Parameter(Mandatory)]
    [string]
    $Domain,

    # Path to the file listing obsolete group names (one per line).
    [Parameter()]
    [string]
    $GroupListPath = 'C:\Scripts\ObsoleteGroups\ObsoleteGroups.csv'
)

#Import the Active Directory module so we can work with AD groups.
Import-Module ActiveDirectory

#Read in the CSV or text file of group names.
$File = Get-Content -Path $GroupListPath

#Loop through each line of the text file and run the following commands for each line:
Foreach ($Group in $File) {
    #Get the members of each group (recursively in case groups are nested) in the specified domain or domain controller.
    #Select the name of each member within the group and then write each name to a CSV file. Each CSV file is named with the name of each security group.
    Get-ADGroupMember -Server $Domain -Identity $Group -Recursive | Export-Csv -Path "C:\Scripts\ObsoleteGroups\Archive\$group.csv" -NoTypeInformation

    <#  * * * * * * * * * *
        This section will require special customization until we further develop the script to pull the full group DN.
        In the interest of time today, I have hard coded some of the information.
        * * * * * * * * * *
    #>
    # TODO: Replace the -group, -ou, and -domain placeholder values with real values for your environment.
    .\Remove-AllGroupMembers.ps1 -group "CN=$Group" -ou 'OU=' -domain 'DC='
    # TODO: Replace -Identity and -TargetPath with the correct DN values for your environment.
    Move-ADObject -Server $Domain -Identity 'CN=ps,DC=' -TargetPath ''
}

#Copy and rename the CSV file with a timestamp to keep as a record of run history.
$timeStamp = Get-Date -Format 'yyyy-MM-dd HH-mm-ss'
Copy-Item -Path $GroupListPath -Destination "C:\Scripts\ObsoleteGroups\Run History\ObsoleteGroups $timeStamp.csv"
