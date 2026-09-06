<#
.SYNOPSIS
Checks and imports an existing managed export with explicit target settings and consent.
.DESCRIPTION
Local imports bypass GitHub environment approvals. This script does not publish agents,
activate workflows, force-overwrite customizations, or repack educational sample files.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetEnvironmentUrl,
    [Parameter(Mandatory)][string]$SolutionFile,
    [Parameter(Mandatory)][string]$ManifestFile,
    [Parameter(Mandatory)][string]$ExpectedSolutionName,
    [Parameter(Mandatory)][string]$DeploymentSettingsFile,
    [string]$CheckerOutputFolder = (Join-Path $PSScriptRoot ("..\out\checker-" + [guid]::NewGuid().ToString('N'))),
    [switch]$ConfirmImport,
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientSecret
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'deployment-common.ps1')
if (-not $ConfirmImport) { throw 'Import is disabled without -ConfirmImport. Local imports bypass GitHub approvals.' }
Assert-EnvironmentUrl $TargetEnvironmentUrl
& (Join-Path $PSScriptRoot 'validate-deployment.ps1') -SolutionFile $SolutionFile `
    -ManifestFile $ManifestFile -ExpectedSolutionName $ExpectedSolutionName `
    -DeploymentSettingsFile $DeploymentSettingsFile
if (Test-Path -LiteralPath $CheckerOutputFolder) { throw 'CheckerOutputFolder must not exist; stale reports cannot authorize import.' }
Connect-Pac -EnvironmentUrl $TargetEnvironmentUrl -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$checkerResult = Invoke-NativeCommand pac @('solution', 'check', '--environment', $TargetEnvironmentUrl, '--path', $SolutionFile, '--outputDirectory', $CheckerOutputFolder)
$checkerResult | Write-Host
Assert-CheckerStatus $checkerResult
& (Join-Path $PSScriptRoot 'validate-checker-results.ps1') -ResultsFolder $CheckerOutputFolder
Invoke-NativeCommand pac @('solution', 'import', '--environment', $TargetEnvironmentUrl, '--path', $SolutionFile,
    '--settings-file', $DeploymentSettingsFile, '--force-overwrite', 'false', '--publish-changes', 'false', '--activate-plugins', 'false')
Write-Host "Managed solution imported into $TargetEnvironmentUrl. Agent publication and flow activation remain separate."
