function Expand-ShortURL {
    <#
        .SYNOPSIS
            Expand shortened URLs.
        .DESCRIPTION
            Expand shortened URLs (does not automatically handle nested shorteners).
        .NOTES
            Modified from @md's great concept at https://xkln.net/blog/expanding-shortened-urls-with-powershell/
    #>
    [Alias("ExpandUrl")]
    Param (
        # The URL to be expanded if provided as a string
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [string]
        $URL,

        # The URL to be expanded if provided as a URI object
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'URI')]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $URI
    )

    if ($URI) {
        $URL = $URI
    }

    try {
        (Invoke-WebRequest -MaximumRedirection 0 -Uri $URL -ErrorAction SilentlyContinue).Headers.Location
    } catch {
        $_.Exception.Response.Headers.Location.OriginalString
    }
}
