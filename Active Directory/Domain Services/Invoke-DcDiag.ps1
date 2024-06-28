function Invoke-DcDiag {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainController
    )
 
    $result = dcdiag /s:$DomainController
    $result | select-string -pattern '\. (.*) \b(passed|failed)\b test (.*)' | foreach {
        $obj = @{
            TestName = $_.Matches.Groups[3].Value
            TestResult = $_.Matches.Groups[2].Value
            Entity = $_.Matches.Groups[1].Value
        }
        [pscustomobject]$obj
    }
}
$result
