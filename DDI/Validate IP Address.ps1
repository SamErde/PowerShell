<#
    SNIPPET: An easy way to validate an IP address.
    https://twitter.com/mdjxkln/status/1416381792899141636

    There are sometimes problems with this approach, so RegEx may still be the best approach.

    [] Responds differently to strings vs integers.
    [] Follows standard of inserting zeroes in octects where an apparent value is not specified. (Example: [IPAddress] 2.2)
#>

$IP = "10.253.26.1"
$IP -eq ([IPAddress]$IP).IPAddressToString
# RESULT: True

$IP = "1"
$IP -eq ([IPAddress]$IP).IPAddressToString
# RESULT: False

$IP = "300.1.1.1"
$IP -eq ([IPAddress]$IP).IPAddressToString
# ERROR: Connot convert value "300.1.1.1" to type "System.Net.IPAddress". Error: "An invalid IP address was specified."

[IPAddress] "10.253.26.1"
<# OUTPUT: 
    Address            : 18545930
    AddressFamily      : InterNetwork
    ScopeId            :
    IsIPv6Multicast    : False
    IsIPv6LinkLocal    : False
    IsIPv6SiteLocal    : False
    IsIPv6Teredo       : False
    IsIPv4MappedToIPv6 : False
    IPAddressToString  : 10.253.26.1
#>