[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SolutionFile,
    [Parameter(Mandatory)][string]$ManifestFile,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')][string]$ExpectedSolutionName,
    [Parameter(Mandatory)][string]$DeploymentSettingsFile,
    [string]$ExpectedRunId,
    [string]$ExpectedRepository,
    [string]$ExpectedCommit
)
. (Join-Path $PSScriptRoot 'deployment-common.ps1')
$manifest = Get-Content -LiteralPath $ManifestFile -Raw | ConvertFrom-Json
$metadata = Get-SolutionMetadata $SolutionFile
if ($manifest.SchemaVersion -ne 1 -or $manifest.SolutionName -cne $ExpectedSolutionName -or
    $metadata.Name -cne $ExpectedSolutionName -or $metadata.Managed -ne '1' -or
    $metadata.Version -cne $manifest.SolutionVersion) {
    throw 'Only a managed export matching the requested solution and manifest is allowed.'
}
$bundle = Split-Path -Parent (Resolve-Path -LiteralPath $ManifestFile).Path
foreach ($entry in @(
    @{ Path = $SolutionFile; Hash = $manifest.ManagedSha256 },
    @{ Path = (Join-Path $bundle 'source_unmanaged.zip'); Hash = $manifest.UnmanagedSha256 },
    @{ Path = (Join-Path $bundle 'settings-template.json'); Hash = $manifest.SettingsTemplateSha256 }
)) {
    if ($entry.Hash -notmatch '^[A-Fa-f0-9]{64}$' -or
        (Get-FileHash -LiteralPath $entry.Path -Algorithm SHA256).Hash -ine $entry.Hash) {
        throw 'Export bundle hash mismatch.'
    }
}
$unmanaged = Get-SolutionMetadata (Join-Path $bundle 'source_unmanaged.zip')
if ($unmanaged.Managed -ne '0' -or $unmanaged.Name -cne $ExpectedSolutionName -or $unmanaged.Version -cne $metadata.Version) {
    throw 'Unmanaged source does not match the managed export.'
}
if ($ExpectedRunId -and ($manifest.ExportRunId -cne $ExpectedRunId -or
    $manifest.Repository -cne $ExpectedRepository -or $manifest.Commit -cne $ExpectedCommit)) {
    throw 'Export provenance does not match the trusted workflow run.'
}
$settingsText = Get-Content -LiteralPath $DeploymentSettingsFile -Raw
if ($settingsText -match '(?i)REPLACE_|contoso|00000000-0000-0000-0000-000000000000') {
    throw 'Deployment settings still contain educational placeholders.'
}
$settings = $settingsText | ConvertFrom-Json
$template = Get-Content -LiteralPath (Join-Path $bundle 'settings-template.json') -Raw | ConvertFrom-Json
foreach ($group in @(
    @{ Name = 'EnvironmentVariables'; Key = 'SchemaName'; Required = @('Value') },
    @{ Name = 'ConnectionReferences'; Key = 'LogicalName'; Required = @('ConnectionId', 'ConnectorId') }
)) {
    $name = $group.Name
    $key = $group.Key
    if ($settings.$name -isnot [array] -or $template.$name -isnot [array]) {
        throw "$name must be an array in both settings files."
    }
    $actualNames = @($settings.$name | ForEach-Object { $_.$key })
    $expectedNames = @($template.$name | ForEach-Object { $_.$key })
    if (@($actualNames | Sort-Object -Unique).Count -ne $actualNames.Count -or
        ($actualNames | Sort-Object | ConvertTo-Json -Compress) -cne ($expectedNames | Sort-Object | ConvertTo-Json -Compress)) {
        throw "$name must contain exactly the keys from the exported settings template, without duplicates."
    }
    foreach ($item in $settings.$name) {
        foreach ($field in $group.Required) {
            if ([string]::IsNullOrWhiteSpace($item.$field)) { throw "$name contains an empty $field." }
        }
        if ($name -eq 'ConnectionReferences') {
            $original = @($template.$name | Where-Object { $_.$key -ceq $item.$key })[0]
            if ($item.ConnectorId -cne $original.ConnectorId) { throw 'ConnectorId differs from the exported reference.' }
        }
    }
}
Write-Host 'Export identity, hashes, and settings shape accepted. This is not proof of tenant compatibility or authorization.'
