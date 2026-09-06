[CmdletBinding()]
param([Parameter(Mandatory)][string]$ResultsFolder)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-CheckerReport {
    param([string]$Content)
    $sarif = $Content | ConvertFrom-Json
    if ($sarif.runs -isnot [array] -or $sarif.runs.Count -eq 0) { throw 'Checker report has no analysis runs.' }
    foreach ($run in $sarif.runs) {
        if ($run.results -isnot [array]) { throw 'Checker report has no results array.' }
        if ($run.results.Count -gt 0) { throw 'Import requires zero checker findings. Review the SARIF output.' }
        if ($run.PSObject.Properties.Name -contains 'invocations') {
            foreach ($invocation in $run.invocations) {
                if (-not $invocation.executionSuccessful) { throw 'Checker analysis failed.' }
            }
        }
    }
}

$reportCount = 0
foreach ($file in Get-ChildItem -LiteralPath $ResultsFolder -Recurse -File) {
    if ($file.Extension -ieq '.sarif') {
        Assert-CheckerReport (Get-Content -LiteralPath $file.FullName -Raw)
        $reportCount++
    } elseif ($file.Extension -ieq '.zip') {
        # PAC downloads ZIPs; the GitHub action uploads extracted SARIF files.
        # Read entries without extracting paths supplied by the archive.
        $archive = [IO.Compression.ZipFile]::OpenRead($file.FullName)
        try {
            $entries = @($archive.Entries | Where-Object { $_.FullName -imatch '\.sarif$' })
            if ($entries.Count -eq 0) { throw 'Checker archive has no SARIF reports.' }
            foreach ($entry in $entries) {
                if ($entry.Length -gt 50MB) { throw 'Checker report exceeds the 50 MB local validation limit.' }
                $reader = [IO.StreamReader]::new($entry.Open())
                try { Assert-CheckerReport $reader.ReadToEnd() } finally { $reader.Dispose() }
                $reportCount++
            }
        } finally { $archive.Dispose() }
    }
}
if ($reportCount -eq 0) { throw 'Checker did not produce a SARIF report; refusing import.' }
