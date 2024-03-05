# Authentication headers are required for every API call
$key = ""
$header = @{Authorization = "GenieKey $key" }

# Get all schedules from OpsGenie and save the data from the API response
$Schedules = (Invoke-RestMethod -Method GET -Headers $header -Uri "https://api.opsgenie.com/v2/schedules").data

# Get the URIs for each schedule. Using an arraylist type is recommended if you know that you'll be adding
# or removing objects from the array. Adding an item to an arraylist will output the index of the new item
# by default, so using "$null =" prevents that output from appearing.
$ScheduleUris = [System.Collections.ArrayList]@()
foreach ($item in $Schedules) {
    $null = $ScheduleUris.Add("https://api.opsgenie.com/v2/schedules/$($item.id)")
} # End of ScheduleUris arraylist

# Create an arraylist that contains details of each team's on call schedule.
$OnCalls = [System.Collections.ArrayList]@()
foreach ($url in $ScheduleUris) {

    # Get all of the desired information by calling the relevant APIs (schedules, users, and contacts).
    # The user API can reference either the users' id value or their username value.
    $ScheduleData = (Invoke-RestMethod -Method GET -headers $header -uri "$url").data
    $OnCallData = (Invoke-RestMethod -Method GET -headers $header -uri "$url/on-calls").data
    $UserId = $OnCallData.onCallParticipants.id
    $UserData = (Invoke-RestMethod -Method GET -headers $header -uri "https://api.opsgenie.com/v2/users/$Userid").Data
    $ContactData = (Invoke-RestMethod -Method GET -headers $header -uri "https://api.opsgenie.com/v2/users/$Userid/contacts").Data

    # Create a temporary custom object that contains the collated details
    $OnCallDetails = [PSCUstomObject]@{
        #TeamId     = ""               # Optionalo, but not needed
        #TeamName   = ""               # Optionalo, but not needed
        #ScheduleId = $ScheduleData.id # Optionalo, but not needed
        ScheduleName = $ScheduleData.name
        OnCallUser = $UserData.fullName
        OnCallEmail = ($ContactData.Where({$_.Method -eq "email"})).to
        OnCallPhone = ($ContactData.Where({$_.Method -eq "voice"})).to
    } # Finished populating temporary custom object

    # Add the object to the $OnCalls arraylist and clear the temporary object. Using $null to suppress host output.
    $null = $OnCalls.Add($OnCallDetails)
    $OnCallDetails = $null
} # End foreach $ScheduleUris

Return $OnCalls | Sort-Object -Property ScheduleName
