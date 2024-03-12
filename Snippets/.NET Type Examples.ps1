# .NET Type Examples:
[System.IO.Path]::GetTempPath()
[System.Globalization.RegionInfo]::CurrentRegion
[IO.File]::ReadAllText($FilePath)

# Using Is Null or Empty
if ([string]::IsNullOrEmpty($customNames)) {
    # Do something
}
