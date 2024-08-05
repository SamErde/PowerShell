$DhcpServer = ''
$output = @()

get-dhcpserverv4scope -computername $DhcpServer | ForEach-Object{
    $ScopeId = $_.ScopeId
    $ScopeName = $_.Name
    $Options = Get-DhcpServerv4OptionValue -All -ComputerName $DhcpServer -ScopeId $ScopeId

    $OptionList = @()

    $Options | ForEach-Object {
        $obj = New-Object System.Object
        $obj | Add-Member -Type NoteProperty -Name ScopeId -Value $ScopeId
        $obj | Add-Member -Type NoteProperty -Name ScopeName -Value $ScopeName
        $obj | Add-Member -Type NoteProperty -Name OptionId -Value $_.OptionId
        $obj | Add-Member -Type NoteProperty -Name OptionName -Value $_.Name
        If ($_.OptionId -eq 51) {
            [int]$Lease = $_.Value[0]
            $LeaseTime = New-Timespan -Seconds $Lease
            $obj | Add-Member -Type NoteProperty -Name OptionValue -Value $LeaseTime
            $obj | Add-Member -Type NoteProperty -Name OptionType -Value 'Time'
        } Else {
            $obj | Add-Member -Type NoteProperty -Name OptionValue -Value ($_.Value -join ';')
            $obj | Add-Member -Type NoteProperty -Name OptionType -Value $_.Type
        }
        $OptionList += $obj
    }

    $obj = New-Object System.Object
    $obj | Add-Member -Type NoteProperty -Name ScopeId -Value $ScopeId
    $obj | Add-Member -Type NoteProperty -Name ScopeName -Value $ScopeName
    $obj | Add-Member -Type NoteProperty -Name OptionName -Value 'StartRange'
    $obj | Add-Member -Type NoteProperty -Name OptionValue -Value $_.StartRange
    $obj | Add-Member -Type NoteProperty -Name OptionType -Value 'IP Address'
    $OptionList += $obj

    $obj = New-Object System.Object
    $obj | Add-Member -Type NoteProperty -Name ScopeId -Value $ScopeId
    $obj | Add-Member -Type NoteProperty -Name ScopeName -Value $ScopeName
    $obj | Add-Member -Type NoteProperty -Name OptionName -Value 'EndRange'
    $obj | Add-Member -Type NoteProperty -Name OptionValue -Value $_.EndRange
    $obj | Add-Member -Type NoteProperty -Name OptionType -Value 'IP Address'
    $OptionList += $obj

    $obj = New-Object System.Object
    $obj | Add-Member -Type NoteProperty -Name ScopeId -Value $ScopeId
    $obj | Add-Member -Type NoteProperty -Name ScopeName -Value $ScopeName
    $obj | Add-Member -Type NoteProperty -Name OptionName -Value 'SubnetMask'
    $obj | Add-Member -Type NoteProperty -Name OptionValue -Value $_.SubnetMask
    $obj | Add-Member -Type NoteProperty -Name OptionType -Value 'IP Address'
    $OptionList += $obj

    $obj = New-Object System.Object
    $obj | Add-Member -Type NoteProperty -Name ScopeId -Value $ScopeId
    $obj | Add-Member -Type NoteProperty -Name ScopeName -Value $ScopeName
    $obj | Add-Member -Type NoteProperty -Name OptionName -Value 'State'
    $obj | Add-Member -Type NoteProperty -Name OptionValue -Value $_.State
    $obj | Add-Member -Type NoteProperty -Name OptionType -Value 'String'
    $OptionList += $obj

    $ExclusionRange = Get-DhcpServerv4ExclusionRange -ComputerName $DhcpServer -ScopeId $ScopeId

    $ExclusionRange | ForEach-Object {
        $obj = New-Object System.Object
        $obj | Add-Member -Type NoteProperty -Name ScopeId -Value $ScopeId
        $obj | Add-Member -Type NoteProperty -Name ScopeName -Value $ScopeName
        $obj | Add-Member -Type NoteProperty -Name OptionId -Value 'Exclusion'
        $obj | Add-Member -Type NoteProperty -Name OptionName -Value $_.StartRange
        $obj | Add-Member -Type NoteProperty -Name OptionValue -Value $_.EndRange
        $obj | Add-Member -Type NoteProperty -Name OptionType -Value 'IP Address'
        $OptionList += $obj
    }

    $output += $OptionList
 }

$output | export-csv $home\Reports\DhcpOptions.csv -NoTypeInformation
