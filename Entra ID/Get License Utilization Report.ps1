# by Daniel Bradley
# https://github.com/orgs/msgraph/discussions/95

Connect-MgGraph -Scope Reports.Read.All

$Report = Invoke-MgGraphRequest -Method GET  -Uri "/beta/reports/azureADPremiumLicenseInsight" -OutputType PSObject

$Report
$Report.p1FeatureUtilizations
$Report.p2FeatureUtilizations
