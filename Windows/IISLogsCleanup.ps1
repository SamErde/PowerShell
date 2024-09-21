<#
.SYNOPSIS
IISLogsCleanup.ps1 - IIS Log File Cleanup Script

.DESCRIPTION 
A PowerShell script to compress and archive IIS log files.

This script will check the folder that you specify, and any files older
than the first day of the previous month will be coDOMAINNAMEsed into a
zip file. If you specify an archive path as well the zip file will be
moved to that location.

The recommended use for this script is a once-monthly scheduled task
run on the first day of each month. This will coDOMAINNAMEs all files older
than the first day of the previous month, resulting in only 1-2 months
of log files being stored on the server.

If the script detects any issues with the archive process that may
indicate that a file was missed it will not delete the log files from
the folder.

The script also writes a log file each time it is run so you can check
the results or troubleshoot any issues.

.PARAMETER Logpath
The IIS log directory to cleanup.

.PARAMETER ArchivePath
The path to a location where zip files are moved to, for example
a central log repository stored on a NAS.

.EXAMPLE
.\IISLogsCleanup.ps1 -Logpath "D:\IIS Logs\W3SVC1"
This example will coDOMAINNAMEs the log files in "D:\IIS Logs\W3SVC1" and leave
the zip files in that location.

.EXAMPLE
.\IISLogsCleanup.ps1 -Logpath "D:\IIS Logs\W3SVC1" -ArchivePath "\\nas01\archives\iislogs"
This example will coDOMAINNAMEs the log files in "D:\IIS Logs\W3SVC1" and move
the zip files to the archive path.

.LINK
http://exchangeserverpro.com/powershell-script-iis-logs-cleanup

.NOTES
Written by: Paul Cunningham

Find me on:

* My Blog:	http://paulcunningham.me
* Twitter:	https://twitter.com/paulcunningham
* LinkedIn:	http://au.linkedin.com/in/cunninghamp/
* Github:	https://github.com/cunninghamp

For more Exchange Server tips, tricks and news
check out Exchange Server Pro.

* Website:	http://exchangeserverpro.com
* Twitter:	http://twitter.com/exchservpro

Additional Credits:
Filip Kasaj - http://ficility.net/2013/02/25/ps-2-0-remove-and-coDOMAINNAMEs-iis-logs-automatically/
Rob Pettigrew - regional date issues
Alain Arnould - Zip file locking issues

License:

The MIT License (MIT)

Copyright (c) 2015 Paul Cunningham

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Change Log
V1.00, 7/04/2014, Initial version
V1.01, 8/08/2015, Fix for regional date format issues, Zip file locking issues.
V1.02, 25/08/2015, Fixed typo in a variable
#>


[CmdletBinding()]
param (
	[Parameter( Mandatory=$true)]
	[string]$Logpath,

    [Parameter( Mandatory=$false)]
    [string]$ArchivePath
	)


#-------------------------------------------------
#  Variables
#-------------------------------------------------

$sleepinterval = 5

$computername = $env:computername

$now = Get-Date
$currentmonth = ($now).Month
$currentyear = ($now).Year
$previousmonth = ((Get-Date).AddMonths(-1)).Month
$firstdayofpreviousmonth = (Get-Date -Year $currentyear -Month $currentmonth -Day 1).AddMonths(-1)

#$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
#$output = "$myDir\IISLogsCleanup.log"
$output = "$LogPath\IISLogsCleanup-$(Get-Date -f yyyyMMddHHmm).log"
$logpathfoldername = $logpath.Split("\")[-1]

#...................................
# Logfile Strings
#...................................

$logstring0 = "====================================="
$logstring1 = " IIS Log File Cleanup Script"


#-------------------------------------------------
#  Functions
#-------------------------------------------------

#This function is used to write the log file for the script
Function Write-Logfile()
{
	param( $logentry )
	$timestamp = Get-Date -DisplayHint Time
	"$timestamp $logentry" | Out-File $output -Append
}

# This function is to test the completion of the async CopyHere method
# Function provided by Alain Arnould
function IsFileLocked( [string]$path)
{
    If ([string]::IsNullOrEmpty($path) -eq $true) {
        Throw "The path must be specified."
    }

    [bool] $fileExists = Test-Path $path

    If ($fileExists -eq $false) {
        Throw "File does not exist (" + $path + ")"
    }

    [bool] $isFileLocked = $true

    $file = $null

    Try
    {
        $file = [IO.File]::Open($path,
                        [IO.FileMode]::Open,
                        [IO.FileAccess]::Read,
                        [IO.FileShare]::None)

        $isFileLocked = $false
    }
    Catch [IO.IOException]
    {
        If ($_.Exception.Message.EndsWith("it is being used by another process.") -eq $false)
        {
            # Throw $_.Exception
            [bool] $isFileLocked = $true
        }
    }
    Finally
    {
        If ($null -ne $file)
        {
            $file.Close()
        }
    }

    return $isFileLocked
}


#-------------------------------------------------
#  Script
#-------------------------------------------------

#Log file is overwritten each time the script is run to avoid
#very large log files from growing over time

$timestamp = Get-Date -DisplayHint Time
"$timestamp $logstring0" | Out-File $output
Write-Logfile $logstring1
Write-Logfile "  $now"
Write-Logfile $logstring0w


#Check whether IIS Logs path exists, exit if it does not
if ((Test-Path $Logpath) -ne $true)
{
    $tmpstring = "Log path $logpath not found"
    Write-Warning $tmpstring
    Write-Logfile $tmpstring
    EXIT
}


$tmpstring = "Current Month: $currentmonth"
Write-Host $tmpstring
Write-Logfile $tmpstring

$tmpstring = "Previous Month: $previousmonth"
Write-Host $tmpstring
Write-Logfile $tmpstring

$tmpstring = "First Day of Previous Month: $firstdayofpreviousmonth"
Write-Host $tmpstring
Write-Logfile $tmpstring

#Fetch list of log files older than 1st day of previous month
$logstoremove = Get-ChildItem -Path "$($Logpath)\*.*" -Include *.log | Where-Object {$_.CreationTime -lt $firstdayofpreviousmonth -and $_.PSIsContainer -eq $false}

if ($null -eq $($logstoremove.Count))
{
    $logcount = 0
}
else
{
    $logcount = $($logstoremove.Count)
}

$tmpstring = "Found $logcount logs earlier than $firstdayofpreviousmonth"
Write-Host $tmpstring
Write-Logfile $tmpstring

#Init a hashtable to store list of log files
$hashtable = @{}

#Add each logfile to hashtable
foreach ($logfile in $logstoremove)
{
    $zipdate = $logfile.LastWriteTime.ToString("yyyy-MM")
    $hashtable.Add($($logfile.FullName),"$zipdate")
}

#Calculate unique yyyy-MM dates from logfiles in hashtable
$hashtable = $hashtable.GetEnumerator() | Sort-Object Value
$dates = @($hashtable | Group-Object -Property:Value | Select-Object Name)

#For each yyyy-MM date add those logfiles to a zip file
foreach ($date in $dates)
{
    $zipfilename = "$Logpath\$computername-$logpathfoldername-$($date.Name).zip"

    if(-not (test-path($zipfilename)))
    {
        set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        (Get-ChildItem $zipfilename).IsReadOnly = $false 
    }

    $shellApplication = new-object -com shell.application
    $zipPackage = $shellApplication.NameSpace($zipfilename)

    $zipfiles = $hashtable | Where-Object {$_.Value -eq "$($date.Name)"}

    $tmpstring = "Zip file name is $zipfilename and will contain $($zipfiles.Count) files"
    Write-Host $tmpstring
    Write-Logfile $tmpstring

    foreach($file in $zipfiles) 
    { 
        $fn = $file.key.ToString()
        
        $tmpstring = "Adding $fn to $zipfilename"
        Write-Host $tmpstring
        Write-Logfile $tmpstring

        $zipPackage.CopyHere($fn,16)

        #This sleep interval helps avoids file lock/conflict issues. May need to increase if larger
        #log files are taking longer to add to the zip file.
        do
        {
            Start-sleep -s $sleepinterval
        }
        while (IsFileLocked($zipfilename))
    }

    #Compare count of log files on disk to count of log files in zip file
    $zippedcount = ($zipPackage.Items()).Count
    
    $tmpstring = "Zipped count: $zippedcount"
    Write-Host $tmpstring
    Write-Logfile $tmpstring
    
    $tmpstring = "Files: $($zipfiles.Count)"
    Write-Host $tmpstring
    Write-Logfile $tmpstring

    #If counts match it is safe to delete the log files from disk
    if ($zippedcount -eq $($zipfiles.Count))
    {
        $tmpstring = "Zipped file count matches log file count, safe to delete log files"
        Write-Host $tmpstring
        Write-Logfile $tmpstring
        foreach($file in $zipfiles) 
        { 
            $fn = $file.key.ToString()
            Remove-Item $fn
        }

        #If archive path was specified move zip file to archive path
        if ($ArchivePath)
        {
            #Check whether archive path is accessible
            if ((Test-Path $ArchivePath) -ne $true)
            {
                $tmpstring = "Log path $archivepath not found or inaccessible"
                Write-Warning $tmpstring
                Write-Logfile $tmpstring
            }
            else
            {
                #Check if subfolder of archive path exists
                if ((Test-Path $ArchivePath\$computername) -ne $true)
                {
                    try 
                    {
                        #Create subfolder based on server name
                        New-Item -Path $ArchivePath\$computername -ItemType Directory -ErrorAction STOP
                    }
                    catch
                    {
                        #Subfolder creation failed
                        $tmpstring = "Unable to create $computername subfolder in $archivepath"
                        Write-Host $tmpstring
                        Write-Logfile $tmpstring

                        $tmpstring = $_.Exception.Message
                        Write-Warning $tmpstring
                        Write-Logfile $tmpstring
                    }
                }

                if ((Test-Path $ArchivePath\$computername\$logpathfoldername) -ne $true)
                {
                    try
                    {
                        #create subfolder based on log path folder name
                        New-Item -Path $ArchivePath\$computername\$logpathfoldername -ItemType Directory -ErrorAction STOP
                    }
                    catch
                    {
                        #Subfolder creation failed
                        $tmpstring = "Unable to create $logpathfoldername subfolder in $archivepath\$computername"
                        Write-Host $tmpstring
                        Write-Logfile $tmpstring

                        $tmpstring = $_.Exception.Message
                        Write-Warning $tmpstring
                        Write-Logfile $tmpstring
                    }
                }

                #Now move the zip file to the archive path
                try 
                {
                    #Move the zip file
                    Move-Item $zipfilename -Destination $ArchivePath\$computername\$logpathfoldername -ErrorAction STOP
                    $tmpstring = "$zipfilename was moved to $archivepath\$computername\$logpathfoldername"
                    Write-Host $tmpstring
                    Write-Logfile $tmpstring
                }
                catch
                {
                    #Move failed, log the error
                    $tmpstring = "Unable to move $zipfilename to $ArchivePath\$computername\$logpathfoldername"
                    Write-Host $tmpstring
                    Write-Logfile $tmpstring
                    Write-Warning $_.Exception.Message
                    Write-Logfile $_.Exception.Message
                }   
            }
        }

    }
    else
    {
        $tmpstring = "Zipped file count does not match log file count, not safe to delete log files"
        Write-Host $tmpstring
        Write-Logfile $tmpstring
    }

}


#Finished
$tmpstring = "Finished"
Write-Host $tmpstring
Write-Logfile $tmpstring


#...................................
# Finished
#...................................
