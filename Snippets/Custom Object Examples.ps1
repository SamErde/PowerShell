$BuildVersion = "23.03.15.2119"

$scriptName = $script:MyInvocation.MyCommand.Name
$scriptPath = [IO.Path]::GetDirectoryName($script:MyInvocation.MyCommand.Path)
$scriptFullName = (Join-Path $scriptPath $scriptName)

$result = [PSCustomObject]@{
    ScriptName     = $scriptName
    CurrentVersion = $BuildVersion
    LatestVersion  = ""
    UpdateFound    = $false
    Error          = $null
}


function CreateCustomCSV {
    param (
        $mailbox,
        $data,
        [string]$CsvPath
    )

    $ItemType = $data.ItemClass

    if ($data.ItemClass.StartsWith("IPM.Note")) {
        $ItemType = "E-Mail"
    } elseif ($data.ItemClass.StartsWith("IPM.Appointment")) {
        $ItemType = "Calendar"
    } elseif ($data.ItemClass.StartsWith("IPM.Task")) {
        $ItemType = "Task"
    }

    $row = [PSCustomObject]@{
        "Mailbox"                     = $mailbox
        "Id"                          = $data.Id
        "ItemType"                    = $ItemType
        "Sender"                      = ($data.From | Select-Object -ExpandProperty Address) -join ","
        "Recipient"                   = ($data.ToRecipients | Select-Object -ExpandProperty Address) -join ","
        "Subject"                     = $data.Subject
        "DateReceived"                = $data.DateTimeReceived
        "PidLidReminderFileParameter" = $data.ExtendedProperties[0].Value
        "Cleanup"                     = "N"
    }

    $row | Export-Csv -Path $CsvPath -NoTypeInformation -Append -Encoding utf8 -Force
}


# "A better way"?
function Find-ESC8 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $ADCSObjects
    )
    process {
        $ADCSObjects | Where-Object {
            $_.CAEnrollmentEndpoint
        } | ForEach-Object {
            $Issue = [ordered] @{
                Forest            = $_.CanonicalName.split('/')[0]
                Name              = $_.Name
                DistinguishedName = $_.DistinguishedName
            }
            if ($_.CAEnrollmentEndpoint -like '^http*') {
                $Issue['Issue'] = 'HTTP enrollment is enabled.'
                $Issue['CAEnrollmentEndpoint'] = $_.CAEnrollmentEndpoint
                $Issue['Fix'] = 'TBD - Remediate by doing 1, 2, and 3'
                $Issue['Revert'] = 'TBD'
            } else {
                $Issue['Issue'] = 'HTTPS enrollment is enabled.'
                $Issue['CAEnrollmentEndpoint'] = $_.CAEnrollmentEndpoint
                $Issue['Fix'] = 'TBD - Remediate by doing 1, 2, and 3'
                $Issue['Revert'] = 'TBD'
            }
            $Issue['Technique'] = 'ESC8'
            [PSCustomObject] $Issue
        }
    }
}