function Get-ADAttributeUniqueValues {
    <#
    .SYNOPSIS
    Get a list of unique values for specified attributes in Active Directory.

    .DESCRIPTION
    This script queries all enabled user accounts in Active Directory and get a list of the unique values that are found
    in the specified attributes. It defaults to checking company, department, location, office, and title. The results
    are exported to a JSON file.

    .PARAMETER AttributesToCheck
    The attribute or list of attributes on AD users to check. (Defaults to company, department, office, and title.)

    .PARAMETER ExportDirectory
    The directory to save the exported JSON file in. (Optional, defaults to C:\Temp.)

    .PARAMETER Filename
    The filename for the exported JSON. (Optional, defaults to ADAttributeUniqueValues.json.)

    .EXAMPLE
    Get-ADAttributeUniqueValues

    Get a list of unique values for the default attributes (company, department, office, and title) and export them to
    C:\Temp\ADAttributeUniqueValues.json.

    .EXAMPLE
    Get-ADAttributeUniqueValues -AttributesToCheck department -ExportDirectory C:\Temp -Filename UniqueAttributes.json

    Get a list of unique department values and export them to C:\Temp\UniqueAttributes.json.

    .NOTES
    Author: Sam Erde
    Company: Sentinel Technologies, Inc
    Modified: 2025-02-20
    Version: 1.0.0

    .LINK
    https://github.com/SamErde

    .LINK
    https://www.sentinel.com
    #>
    [CmdletBinding()]
    param (
        # The attribute or list of attributes on AD users to check. (Defaults to company, department, office, and title.)
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('company', 'country', 'department', 'homeDrive', 'l', 'physicalDeliveryOfficeName', 'postalCode', 'state', 'streetAddress', 'title')]
        [string[]]
        $AttributesToCheck = @('Company', 'Department', 'Office', 'Title'),

        # The directory to save the exported JSON file in. (Optional, defaults to C:\Temp.)
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -Path $_ -PathType Container })]
        [string]
        $ExportDirectory = 'C:\Temp',

        # The filename for the exported JSON. (Optional, defaults to ADAttributeUniqueValues.json.)
        [Parameter()]
        [string]
        $Filename = 'ADAttributeUniqueValues.json'
    )

    begin {
        Start-Transcript -Path (Join-Path $ExportDirectory -ChildPath 'Get-ADAttributeUniqueValues.log') -Append -NoClobber
        # Create a hashtable to store the list of unique values for each attribute.
        $AttributeValues = @{}
        Write-Verbose "Checking attributes: $($AttributesToCheck -join ', ')"

        # Create the full path for the exported JSON file.
        $ExportPath = Join-Path -Path $ExportDirectory -ChildPath $Filename
        Write-Verbose "Export Path: $ExportPath"
    }

    process {
        # Get all enabled users from Active Directory with the specified attributes.
        Import-Module ActiveDirectory -Verbose:$false
        $Users = Get-ADUser -Filter 'Enabled -eq $true' -Properties $AttributesToCheck
        Write-Verbose "[+] Analyzing $($Users.Count) users." -Verbose
        if ($Users.Count -eq 0 -or -not $Users) {
            throw 'Failed to enumerate user objects.'
        }

        # Loop through the list of attributes to check and add their unique values to a hash table.
        foreach ($Attribute in $AttributesToCheck) {
            Write-Verbose "    | Checking attribute: $Attribute"
            $KeyName = "${Attribute}Values"

            # In the hash table, store the attribute name as the key. In the item's value property, create a (nested) list object to store the unique values for the AD attribute.
            $AttributeValues[$KeyName] = New-Object -TypeName 'System.Collections.Generic.List[System.String]'

            # Get all unique, sorted values in use for the current attribute and then add them to the list (if any).
            $UniqueValues = [string[]]($Users | Select-Object -ExpandProperty $Attribute -Unique | Sort-Object)
            Write-Verbose "    --- Found $($UniqueValues.Count) unique values for $Attribute"
            if ($UniqueValues.Count -gt 0) {
                $AttributeValues[$KeyName].AddRange($UniqueValues)
            }
        }

        # Export the hash table to a JSON file.
        $AttributeValues | ConvertTo-Json | Out-File -FilePath $ExportPath -Force
        Write-Verbose "[+] Exported results to $(Resolve-Path -Path $ExportPath)"
    }

    end {
        Remove-Variable Attribute, AttributesToCheck, AttributeValues, ExportDirectory, ExportPath, Filename, KeyName, UniqueValues, Users -ErrorAction SilentlyContinue
        Write-Verbose 'Cleaning up.'
        Stop-Transcript
    }
}
