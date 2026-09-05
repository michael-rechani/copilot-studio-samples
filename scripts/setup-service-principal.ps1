<#
.SYNOPSIS
    Automates creating an Azure Entra ID App Registration & Client Secret for Power Platform CI/CD pipelines.

.DESCRIPTION
    Uses the Azure CLI (az) to register an application, configure permissions, and generate a client secret.

.EXAMPLE
    .\setup-service-principal.ps1 -AppName "GitHub-CopilotStudio-Deployer"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AppName = "GitHub-CopilotStudio-Deployer"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " 🔐 Azure Service Principal Setup for Power Platform" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# Verify Azure CLI
if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI ('az') is not installed. Please install Azure CLI before running this script."
}

Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$account = az account show | ConvertFrom-Json
if (-not $account) {
    az login
    $account = az account show | ConvertFrom-Json
}

$tenantId = $account.tenantId
Write-Host "Connected to Tenant ID: $tenantId" -ForegroundColor Green

# 1. Create App Registration
Write-Host "`n[1/3] Creating Entra ID App Registration '$AppName'..." -ForegroundColor Yellow
$appJson = az ad app create --display-name $AppName --sign-in-audience "AzureADMyOrg" | ConvertFrom-Json
$appId = $appJson.appId

# 2. Create Service Principal
Write-Host "[2/3] Creating Service Principal..." -ForegroundColor Yellow
az ad sp create --id $appId | Out-Null

# 3. Create Client Secret
Write-Host "[3/3] Generating 1-Year Client Secret..." -ForegroundColor Yellow
$secretJson = az ad app credential reset --id $appId --append --years 1 | ConvertFrom-Json
$clientSecret = $secretJson.password

Write-Host "`n🎉 Service Principal successfully created!" -ForegroundColor Green
Write-Host "------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Tenant ID:       $tenantId"
Write-Host "Client (App) ID: $appId"
Write-Host "Client Secret:   $clientSecret"
Write-Host "------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Next Step: Add this App ID as an Application User in Power Platform Admin Center:" -ForegroundColor Yellow
Write-Host "1. Go to https://admin.powerplatform.microsoft.com"
Write-Host "2. Select Environment -> Settings -> Users + permissions -> Application users"
Write-Host "3. Add '$appId' and grant the 'System Administrator' role."
