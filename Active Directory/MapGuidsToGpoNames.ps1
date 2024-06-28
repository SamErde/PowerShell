function Get-GuidToGpoName {
    <#
        .SYNOPSIS
            This script maps GUIDs to GPO display names in the SYSVOL share on a domain controller.

        .DESCRIPTION
            This script looks at every GPO directory in a domain's SYSVOL share and
            inspects the XML contents to map GUID directory names to GPO display names.

        .PARAMETER Path
            The path to the Policies directory in the SYSVOL share on a domain controller.

        .EXAMPLE
            Get-GuidToGpoName -Path \\dc1\sysvol\domain.com\Policies
            This example will return a table of GPO display names and their corresponding GUIDs.
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [String]
        $Path
    )
    
    begin {
        
    }
    
    process {
        $Results = @{}
        Get-ChildItem -Recurse -Include backup.xml $Path | ForEach-Object {
            $GUID = $_.Directory.Name
            $XML = [xml](Get-Content $_)
            $DN = $XML.GroupPolicyBackupScheme.GroupPolicyObject.GroupPolicyCoreSettings.DisplayName.InnerText
            $Results.Add($DN, $GUID)
        }
        $Results | Format-Table Name, Value -AutoSize
    }
    
    end {
        
    }
}
