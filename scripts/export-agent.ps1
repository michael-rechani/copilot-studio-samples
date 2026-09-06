<#
.SYNOPSIS
Exports managed and unmanaged archives from a real Dev solution. Never packs samples.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$EnvironmentUrl,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z_][A-Za-z0-9_]*$')][string]$SolutionName,
    [string]$OutputFolder = (Join-Path $PSScriptRoot '..\out\export'),
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientSecret
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'deployment-common.ps1')
Assert-EnvironmentUrl $EnvironmentUrl
if (Test-Path -LiteralPath $OutputFolder) {
    throw 'OutputFolder must not exist. Choose a fresh folder to prevent stale artifact reuse.'
}
Connect-Pac -EnvironmentUrl $EnvironmentUrl -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
New-Item -ItemType Directory -Path $OutputFolder | Out-Null
$managed = Join-Path $OutputFolder 'solution.zip'
$unmanaged = Join-Path $OutputFolder 'source_unmanaged.zip'
Invoke-NativeCommand pac @('solution', 'export', '--environment', $EnvironmentUrl, '--name', $SolutionName, '--path', $managed, '--managed')
Invoke-NativeCommand pac @('solution', 'export', '--environment', $EnvironmentUrl, '--name', $SolutionName, '--path', $unmanaged)
$managedMetadata = Get-SolutionMetadata $managed
$unmanagedMetadata = Get-SolutionMetadata $unmanaged
if ($managedMetadata.Managed -ne '1' -or $unmanagedMetadata.Managed -ne '0' -or
    $managedMetadata.Name -cne $SolutionName -or $unmanagedMetadata.Name -cne $SolutionName -or
    $managedMetadata.Version -cne $unmanagedMetadata.Version) {
    throw 'Exported archives do not form a managed/unmanaged pair of the requested solution/version.'
}
$settingsTemplate = Join-Path $OutputFolder 'settings-template.json'
Invoke-NativeCommand pac @('solution', 'create-settings', '--solution-zip', $managed, '--settings-file', $settingsTemplate)
$manifest = [ordered]@{
    SchemaVersion = 1
    SolutionName = $SolutionName
    SolutionVersion = $managedMetadata.Version
    ManagedSha256 = (Get-FileHash -LiteralPath $managed -Algorithm SHA256).Hash
    UnmanagedSha256 = (Get-FileHash -LiteralPath $unmanaged -Algorithm SHA256).Hash
    SettingsTemplateSha256 = (Get-FileHash -LiteralPath $settingsTemplate -Algorithm SHA256).Hash
    Repository = $env:GITHUB_REPOSITORY
    ExportRunId = $env:GITHUB_RUN_ID
    Commit = $env:GITHUB_SHA
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputFolder 'manifest.json') -Encoding utf8
Write-Host "Export complete in $OutputFolder. Freeze Dev edits during export; review both archives before promotion."
