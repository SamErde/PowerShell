function Update-ModuleVersion {
    [CmdletBinding(DefaultParameterSetName = 'Minor')]
    [OutputType([String])]
    param (

        # Specify the version to update from (or read from a module manifest).
        [version] $InputVersion,

        # Basic version switches.
        [Parameter(ParameterSetName = 'Major')]
        [Switch] $Major,

        [Parameter(ParameterSetName = 'Minor')]
        [Switch] $Minor,

        [Parameter(ParameterSetName = 'Patch')]
        [Switch] $Patch,

        [Parameter()]
        [ValidateScript({ $_ -match '^(?:[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)$' })]
        [string] $PrereleaseTag

    )

    process {
        # $Version = Get-ModuleVersion
        # $IsPrerelease = Get-ModuleVersion -Prerelease
        if ($InputVersion) {
            $Version = $InputVersion
            Write-Verbose -Message "InputVersion: $InputVersion"
        }
        $VersionParts = [ordered]@{
            Major = $Version.Major
            Minor = $Version.Minor
            Patch = $Version.Build
        }
        Write-Verbose -Message "VersionParts: `n$($VersionParts | Out-String)"


        #region IncrementVersion
        if ($Major.IsPresent) {
            $VersionParts.Major++
            $VersionParts.Minor = 0
            $VersionParts.Patch = 0
        }

        if ($Minor.IsPresent) {
            $VersionParts.Minor++
            $VersionParts.Patch = 0
        }

        if ($Patch.IsPresent ) {
            $VersionParts.Patch++
        }
        #endregion IncrementVersion


        #region Prerelease
        if ($PrereleaseTag ) {
            # Prepend a hyphen to the prerelease tag if it is specified.
            Write-Verbose -Message "`nPrereleaseTag: $PrereleaseTag"
            $PrereleaseTag = "-$PrereleaseTag"

            # Warn if the prerelease tag is added but the major, minor, and patch versions are not incremented.
            if (-not ($Major.IsPresent -or $Minor.IsPresent -or $Patch.IsPresent)) {
                Write-Warning -Message "The prerelease tag '$PrereleaseTag' was added but the major, minor, or patch version was not incremented." -WarningAction Continue
            }
        }
        #endregion Prerelease


        #region ValidateVersion
        $NewVersion = $VersionParts.Major, $VersionParts.Minor, $VersionParts.Patch -Join '.'
        if ($NewVersion -eq $Version) {
            Write-Warning -Message 'The version did not change.' -WarningAction Continue
        }

        # https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
        $PatternValidation = '^(?<Major>0|[1-9]\d*)\.(?<Minor>0|[1-9]\d*)\.(?<patch>0|[1-9]\d*)(?:-(?<Prerelease>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?<BuildMetadata>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$'
        if ($NewVersion -notmatch $PatternValidation) {
            Write-Error -Message "The new version '$NewVersion' is not a valid semantic version." -ErrorAction Continue
        } else {
            foreach ($match in $matches.GetEnumerator()) {
                "$($match.Key)" | Write-Debug -Debug
            }
        }

        if ("$NewVersion$PrereleaseTag" -notmatch $PatternValidation) {
            Write-Error -Message "The prerelease version '$PrereleaseVersion' is not a valid semantic version." -ErrorAction Continue
        } else {
            $matches | Write-Debug -Debug
            foreach ($match in $matches.GetEnumerator()) {
                "$($match.Key)" | Write-Debug -Debug
            }
        }
        #endregion ValidateVersion


        # Update-ModuleManifest -Path (Get-ModuleManifestFile).FullName -ModuleVersion $NewVersion
    }

    begin {}

    end {
        Write-Output "$NewVersion$PrereleaseTag"
    }
}
