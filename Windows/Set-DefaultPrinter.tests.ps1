Describe 'Set-DefaultPrinter' {

    BeforeAll {
        . $PSScriptRoot\Set-DefaultPrinter.ps1
    }

    Context 'When no printer name is provided' {

        It 'Should list installed printers' {

            Mock Get-Printer {
                return @(
                    [PSCustomObject]@{ Name = "Printer1" }
                    [PSCustomObject]@{ Name = "Printer2" }
                )
            }

            Mock Write-Host {}

            Set-DefaultPrinter

            Assert-MockCalled Get-Printer
            Assert-MockCalled Write-Host
        }
    }

    Context 'When a valid printer name is provided' {

        It 'Should set the default printer' {

            Mock Get-Printer {
                return @(
                    [PSCustomObject]@{ Name = "Printer1" }
                    [PSCustomObject]@{ Name = "Printer2" }
                )
            }

            Mock Get-CimInstance {
                $PrinterMock = [Microsoft.Management.Infrastructure.CimInstance]::new('Win32_Printer','root/cimv2')
                $PrinterName = [Microsoft.Management.Infrastructure.CimProperty]::Create('Name','Printer1', [cimtype]::String, 'Property, ReadOnly')
                $PrinterMock.CimInstanceProperties.Add($PrinterName)
                
                return $PrinterMock
            }

            Mock Invoke-CimMethod {
                return $null
            }

            Set-DefaultPrinter -PrinterName "Printer1"

            Assert-MockCalled Get-CimInstance -Exactly -Times 1 -Scope It -ParameterFilter { $Filter -eq "Name='Printer1'" }

            Assert-MockCalled Invoke-CimMethod -Exactly -Times 1 -Scope It -ParameterFilter { $MethodName -eq "SetDefaultPrinter" }
        }
    }

    Context 'When an invalid printer name is provided' {

        It 'Should throw an error' {

            Mock Get-Printer {
                return @(
                    [PSCustomObject]@{ Name = "Printer1" }
                    [PSCustomObject]@{ Name = "Printer2" }
                )
            }

            Mock Get-CimInstance {
                return $null
            }

            { Set-DefaultPrinter -PrinterName "InvalidPrinter" } | Should -Throw
        }
    }
}
