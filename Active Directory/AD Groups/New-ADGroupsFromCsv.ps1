function New-ADGroupsFromCsv {
    <#
    .SYNOPSIS
    Create multiple Active Directory groups from a CSV file.

    .DESCRIPTION
    This function creates multiple Active Directory groups from data in a CSV file.

    .PARAMETER CsvFile
    CSV file that contains information about the groups to create.
    Required columns include: displayname, name, samaccountname, category (security / distribution), scope (global, domainlocal, universal), description.

    .PARAMETER Server
    Domain controller to run ActiveDirectory cmdlets on.

    .EXAMPLE
    New-AdGroupsFromCsv -CsvFile '.\Groups.csv' -Server 'DC1.example.com'

    .NOTES
    Author: Sam Erde
    Modified: 2024/10/31
    Version: 0.1.0
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('SupportsShouldProcess', '')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    param (
        # CSV file with group names and descriptions (validate path)
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ if (Test-Path -Path $_ -ErrorAction SilentlyContinue ) { $true } })]
        [string]
        $CsvFile,

        # Domain controller to create the new groups on (validate connectivity before executing)
        [Parameter()]
        [ValidateNotNullOrEmpty]
        [ValidateScript({ if (Test-NetConnection -ComputerName $_ -Port 9389 -ErrorAction SilentlyContinue) { $true } })]
        [string]
        $Server
    )

    begin {

        try {
            $GroupList = Import-Csv -Path $CsvFile
        } catch {
            Write-Error "Failed to import the CSV file: $CsvFile. `n$_"
            return
        }

        # Ensure required columns are present in the CSV before continuing
        $RequiredColumns = @('displayname', 'name', 'samaccountname', 'category', 'scope', 'description')
        $CsvColumns = $GroupList | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
        $MissingColumns = $RequiredColumns | Where-Object { $_ -notin $CsvColumns }
        if ($MissingColumns.Count -eq 0) {
            continue
        } else {
            Write-Error "The following required columns are missing from the CSV file: $MissingColumns"
            return
        }

    } # end begin block

    process {

        foreach ($group in $GroupList) {
            $GroupParams = @{
                DisplayName    = $group.DisplayName
                Name           = $group.Name
                SamAccountName = $group.SamAccountName
                GroupCategory  = $group.Category
                GroupScope     = $group.Scope
                Description    = $group.Description
                Server         = $Server
            }
            try {
                New-ADGroup @GroupParams
            } catch {
                throw $_
            }
        }

    } # end process block

    end {

    } # end end block

} # end New-ADGroupsFromCsv function
