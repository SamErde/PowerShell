# Interesting notes: https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel


# Works with .NET Framework 4.5 or newer
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Compatibility with systems that have anything older than .NET Frameworks 4.5
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072



# ========== Enable multiple versions of SSL/TLS for the session ========== #
# SecurityProtocol is an Enum with the [Flags] attribute, so you can do this:
[Net.ServicePointManager]::SecurityProtocol =
[Net.SecurityProtocolType]::Tls13 -bor `
    [Net.SecurityProtocolType]::Tls12

# Also works:
[Net.ServicePointManager]::SecurityProtocol = 'Tls13, TLS12, Tls11'

# Also works:
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls11

# Valid protocol type values, but should not longer be used: Tls11, Tls, Ssl3


# ========== Disable Certificate Validation ========== #
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
    $certCallback = @'
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if (ServicePointManager.ServerCertificateValidationCallback == null)
            {
                ServicePointManager.ServerCertificateValidationCallback +=
                    delegate
                    (
                        Object obj,
                        X509Certificate certificate,
                        X509Chain chain,
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
'@
    Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()
# ========== Disable Certificate Validation ========== #
