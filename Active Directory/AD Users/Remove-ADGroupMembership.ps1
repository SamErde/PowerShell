function Remove-AllADGroupMembership {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        $User
    )
    begin {

    }
    process {
        $UserObject = Get-ADUser $User -Properties memberof
        $SamAccountName = $UserObject.$SamAccountName
        $UserObject.memberof | ForEach-Object {
            # Implement ShouldProcess to support -WhatIf and -Confirm
            if ($PSCmdlet.ShouldProcess($UserObject)) {
                Get-ADGroup $_ | Remove-ADGroupMember -Member $SamAccountName
            }
        }
    }
    end {

    }
}
