function Expand-ShortURL {
    <#
    .SYNOPSIS
    Expand shortened URLs to reveal their destination.

    .DESCRIPTION
    Expands shortened URLs by revealing the Location header of the destination address. This function handles
    single-level redirects only and does not automatically resolve nested shorteners.

    .PARAMETER URL
    The shortened URL to expand. Can be provided as a string or URI object.

    .OUTPUTS
    System.String
    Returns the expanded URL as a string, or the original URL if no redirect is found.

    .EXAMPLE
    Expand-ShortURL -URL "https://bit.ly/3example"

    Expands a bit.ly shortened URL to its full destination.

    .EXAMPLE
    "https://tinyurl.com/example", "https://bit.ly/another" | Expand-ShortURL

    Demonstrates pipeline usage to expand multiple URLs.

    .NOTES
    Inspired by @md's concept at https://xkln.net/blog/expanding-shortened-urls-with-powershell/

    This function uses HTTP HEAD requests with zero redirects to capture the Location header.
    Some URL shorteners may require different approaches or may block automated requests.

    .LINK
    https://xkln.net/blog/expanding-shortened-urls-with-powershell/
    #>
    [CmdletBinding()]
    [Alias('ExpandUrl')]
    param (
        # The shortened URL to expand
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('URI', 'Link')]
        [string]$URL
    )

    process {
        Write-Verbose "Attempting to expand URL: $URL"

        try {
            # Ensure URL has a scheme
            if ($URL -notmatch '^https?://' -and $URL -notmatch '^http?://') {
                $URL = "https://$URL"
                Write-Verbose "Added HTTPS scheme to URL: $URL"
            }

            # Try to get redirect location using HEAD request with zero redirects
            $Response = Invoke-WebRequest -Uri $URL -Method Head -MaximumRedirection 0 -ErrorAction Stop

            # If we get here, there was no redirect
            Write-Verbose "No redirect found for: $URL"
            return $URL

        } catch [System.Net.WebException] {
            # Check if this is a redirect response (3xx status codes)
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode -match '^3\d\d$') {
                $ExpandedUrl = $_.Exception.Response.Headers.Location
                if ($ExpandedUrl) {
                    Write-Verbose "Expanded URL: $URL -> $ExpandedUrl"
                    return $ExpandedUrl.ToString()
                }
            }

            Write-Warning "Failed to expand URL '$URL': $($_.Exception.Message)"
            return $URL

        } catch {
            Write-Warning "Unexpected error expanding URL '$URL': $($_.Exception.Message)"
            return $URL
        }
    }
}
