$items = @{
    'laptop'    = { $args[0] * 600 }
    'rasppi'    = { param($x = 1) $x * 5 }
    'arduino'   = { param($x = 1) $x * 50 }
}

$quantity = 4
$value = &$items['laptop'] $quantity
'The value of {0} laptops is ${1}' -f $quantity, $value

$quantity = 2
$value = &$items['rasppi'] $quantity
'The value of {0} pi is ${1}' -f $quantity, $value



$Files = @{
    OpenSSL = Join-Path -Path $Home -ChildPath "Documents\Tools\OpenSSL-Win64-3.0.0\bin\openssl.exe"
    Config  = Join-Path -Path $WorkingDir -ChildPath "$ShortName.txt"
    Csr     = Join-Path -Path $WorkingDir -ChildPath "$ShortName.csr"
    Key     = Join-Path -Path $WorkingDir -ChildPath "$ShortName.key"
    KeyTmp  = Join-Path -Path $WorkingDir -ChildPath "$ShortName.key.tmp"
    Cert    = Join-Path -Path $WorkingDir -ChildPath "$ShortName.crt"
    PFX     = Join-Path -Path $WorkingDir -ChildPath "$ShortName.pfx"
}

$Files.OpenSSL
$Files.Config
