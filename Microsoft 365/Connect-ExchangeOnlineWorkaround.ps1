function Connect-ExchangeOnlineWorkaround {
    # Get a token and connect to Exchange Online
    # Inspired by https://david-homer.blogspot.com/2025/01/exchange-online-management-powershell.html

    <# To Do:
    - Choose different environments to connect to
    - Add error handling
    #>
    $ExoMsalPath = [System.IO.Path]::GetDirectoryName((Get-InstalledModule -Name 'ExchangeOnlineManagement').Path)
    Add-Type -Path "$ExoMsalPath\Microsoft.IdentityModel.Abstractions.dll"
    Add-Type -Path "$ExoMsalPath\Microsoft.Identity.Client.dll"
    [Microsoft.Identity.Client.IPublicClientApplication] $ExoApplication = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::Create('fb78d390-0c51-40cd-8e17-fdbfab77341b').WithDefaultRedirectUri().Build()
    $ExoAuthToken = $ExoApplication.AcquireTokenInteractive([string[]]'https://outlook.office365.com/.default').ExecuteAsync().Result
    Connect-ExchangeOnline -AccessToken $ExoAuthToken.AccessToken -UserPrincipalName $ExoAuthToken.Account.Username
}
