<#
.SYNOPSIS
    Exports an unmanaged Copilot Studio solution from a Power Platform environment and unpackages it into source control.

.DESCRIPTION
    Uses the Microsoft Power Platform CLI (pac) to authenticate via Service Principal or interactive login,
    export the solution archive, and unpack it into individual human-readable YAML and XML files.

.PARAMETER EnvironmentUrl
    The URL of the source Dataverse environment (e.g., https://org-dev.crm.dynamics.com).

.PARAMETER SolutionName
    The unique name of the solution in Dataverse (e.g., FAQSupportAgent).

.PARAMETER OutputFolder
    The target folder in the git repository where unpacked files will be placed.

.EXAMPLE
    .\export-agent.ps1 -EnvironmentUrl "https://contoso-dev.crm.dynamics.com" -SolutionName "FAQSupportAgent"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentUrl,

    [Parameter(Mandatory = $false)]
    [string]$SolutionName = "FAQSupportAgent",

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "../samples/faq-support-agent",

    [Parameter(Mandatory = $false)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string]$ClientId,

    [Parameter(Mandatory = $false)]
    [string]$ClientSecret
)

$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " 🤖 Copilot Studio Solution Exporter (PAC CLI)" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Check if pac CLI is installed
if (-not (Get-Command "pac" -ErrorAction SilentlyContinue)) {
    Write-Error "Power Platform CLI ('pac') is not installed. Install it with: dotnet tool install --global Microsoft.PowerPlatform.CLI.Tool"
}

# 1. Authenticate
Write-Host "`n[1/4] Authenticating with Power Platform ($EnvironmentUrl)..." -ForegroundColor Yellow
if ($TenantId -and $ClientId -and $ClientSecret) {
    pac auth create --url $EnvironmentUrl --tenant $TenantId --applicationId $ClientId --clientSecret $ClientSecret --name "ExportSession"
} else {
    Write-Host "No SPN credentials provided. Initiating interactive browser login..." -ForegroundColor Gray
    pac auth create --url $EnvironmentUrl --name "ExportSession"
}

# 2. Prepare export directories
$tempExportDir = Join-Path $PSScriptRoot "../out/export"
if (-not (Test-Path $tempExportDir)) {
    New-Item -ItemType Directory -Path $tempExportDir -Force | Out-Null
}
$zipFilePath = Join-Path $tempExportDir "$($SolutionName)_unmanaged.zip"

# 3. Export unmanaged solution from environment
Write-Host "`n[2/4] Exporting unmanaged solution '$SolutionName'..." -ForegroundColor Yellow
pac solution export --name $SolutionName --path $zipFilePath --managed $false --overwrite

# 4. Unpack solution into clean source control files
Write-Host "`n[3/4] Unpacking solution archive into '$OutputFolder'..." -ForegroundColor Yellow
$resolvedOutputFolder = Resolve-Path (Join-Path $PSScriptRoot $OutputFolder) -ErrorAction SilentlyContinue
if (-not $resolvedOutputFolder) {
    $resolvedOutputFolder = Join-Path $PSScriptRoot $OutputFolder
    New-Item -ItemType Directory -Path $resolvedOutputFolder -Force | Out-Null
}

pac solution unpack --zipFile $zipFilePath --folder $resolvedOutputFolder --packagetype Both --overwrite

Write-Host "`n[4/4] ✅ Solution export and unpacking complete!" -ForegroundColor Green
Write-Host "Unpacked files are ready in: $resolvedOutputFolder" -ForegroundColor Green
