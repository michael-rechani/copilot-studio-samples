<#
.SYNOPSIS
    Packs a source-controlled Copilot Studio solution and imports it as a Managed solution into a target environment.

.DESCRIPTION
    Uses Microsoft Power Platform CLI (pac) to build a Managed zip archive from repository files,
    imports the solution into the target Dataverse environment, and publishes all customizations.

.PARAMETER TargetEnvironmentUrl
    The URL of the destination Dataverse environment (e.g., https://org-prod.crm.dynamics.com).

.PARAMETER SourceFolder
    The source directory containing the unpacked solution files.

.PARAMETER Managed
    Whether to deploy as a Managed solution (default: true for Prod/Test).

.EXAMPLE
    .\import-agent.ps1 -TargetEnvironmentUrl "https://contoso-prod.crm.dynamics.com" -SourceFolder "../samples/faq-support-agent"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetEnvironmentUrl,

    [Parameter(Mandatory = $false)]
    [string]$SourceFolder = "../samples/faq-support-agent",

    [Parameter(Mandatory = $false)]
    [bool]$Managed = $true,

    [Parameter(Mandatory = $false)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string]$ClientId,

    [Parameter(Mandatory = $false)]
    [string]$ClientSecret
)

$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " 🚀 Copilot Studio Solution Pack & Importer" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Check pac CLI
if (-not (Get-Command "pac" -ErrorAction SilentlyContinue)) {
    Write-Error "Power Platform CLI ('pac') is not installed. Run: dotnet tool install --global Microsoft.PowerPlatform.CLI.Tool"
}

$resolvedSource = Resolve-Path (Join-Path $PSScriptRoot $SourceFolder)
$packageType = if ($Managed) { "Managed" } else { "Unmanaged" }

# 1. Authenticate
Write-Host "`n[1/4] Authenticating to target environment ($TargetEnvironmentUrl)..." -ForegroundColor Yellow
if ($TenantId -and $ClientId -and $ClientSecret) {
    pac auth create --url $TargetEnvironmentUrl --tenant $TenantId --applicationId $ClientId --clientSecret $ClientSecret --name "DeploySession"
} else {
    Write-Host "Initiating interactive browser login..." -ForegroundColor Gray
    pac auth create --url $TargetEnvironmentUrl --name "DeploySession"
}

# 2. Pack solution
$tempDropDir = Join-Path $PSScriptRoot "../out/drop"
if (-not (Test-Path $tempDropDir)) {
    New-Item -ItemType Directory -Path $tempDropDir -Force | Out-Null
}
$zipOutput = Join-Path $tempDropDir "solution_$($packageType).zip"

Write-Host "`n[2/4] Packing source folder into $packageType solution archive..." -ForegroundColor Yellow
pac solution pack --zipFile $zipOutput --folder $resolvedSource --packagetype $packageType

# 3. Import solution
Write-Host "`n[3/4] Importing solution package into target environment..." -ForegroundColor Yellow
pac solution import --path $zipOutput --force-overwrite --publish-changes --activate-plugins

# 4. Publish customizations
Write-Host "`n[4/4] Publishing all customizations and activating Copilot Agent..." -ForegroundColor Yellow
pac solution publish

Write-Host "`n✅ Successfully deployed Copilot Studio Agent to $TargetEnvironmentUrl!" -ForegroundColor Green
