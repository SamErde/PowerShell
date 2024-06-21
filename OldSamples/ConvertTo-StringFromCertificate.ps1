# Convert a B64 encoded certificate file to a string for use in scripts.
function ConvertTo-StringFromCertificate {
    [CmdletBinding()]
    param (
        [string]$FileName
    )
    
    begin {
        if (!(Test-Path -Path $FileName)) {
            Write-Output "The filename was not found."
            Break
        }
    }
    
    process {
        $certFile = $FileName
        $cert = [IO.File]::ReadAllText($certFile)
        $cert = $cert.replace("-----BEGIN CERTIFICATE-----","")
        $cert = $cert.replace("-----END CERTIFICATE-----","")
        $cert = $cert.replace("`r","")
        $cert = $cert.replace("`n","")
    }
    end {
        
    }
}
