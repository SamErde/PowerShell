function Get-ExchangeVirtualDirectories {
    <#
    .SYNOPSIS
        Get all Exchange Server virtual directories on the current server.
    .DESCRIPTION
        A fun way to find every cmdlet that gets Exchange virtual directories and then pipe that list
        to run it on the current server.
    #>
    foreach ( $command in ( (Get-Command "Get*VirtualDirectory" -CommandType Function).Name ) ) {
        & $command -server $env:COMPUTERNAME | Format-List Name,InternalUrl,ExternalUrl
    }
}
