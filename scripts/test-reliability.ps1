<#
.SYNOPSIS
Offline regression checks. Synthetic archives below are test data, never deployable samples.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'deployment-common.ps1')
$root = Split-Path -Parent $PSScriptRoot
$count = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:count++
}
function Assert-Rejected {
    param([scriptblock]$Action, [string]$MessagePattern)
    $rejected = $false
    try { & $Action | Out-Null } catch {
        if ($_.Exception.Message -notmatch $MessagePattern) { throw }
        $rejected = $true
    }
    Assert-True $rejected "Expected rejection matching: $MessagePattern"
}
function Write-TestArchive {
    param([string]$Path, [string]$Managed)
    $zip = [IO.Compression.ZipFile]::Open($Path, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $writer = [IO.StreamWriter]::new($zip.CreateEntry('solution.xml').Open())
        try {
            $writer.Write("<ImportExportXml><SolutionManifest><UniqueName>TestOnly</UniqueName><Version>1.0.0.0</Version><Managed>$Managed</Managed></SolutionManifest></ImportExportXml>")
        } finally { $writer.Dispose() }
    } finally { $zip.Dispose() }
}

foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.ps1') {
    $tokens = $null
    $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    Assert-True ($errors.Count -eq 0) "PowerShell syntax error in $($file.Name): $errors"
}
Assert-Rejected { Invoke-NativeCommand (Join-Path $PSHOME 'pwsh.exe') @('-NoProfile', '-Command', 'exit 17') } 'exit code 17'
Assert-Rejected { Assert-EnvironmentUrl '' } 'HTTPS environment'
Assert-Rejected { Assert-EnvironmentUrl 'http://test.invalid' } 'HTTPS environment'
Assert-Rejected { Assert-EnvironmentUrl 'https://test.invalid/path' } 'HTTPS environment'
Assert-Rejected { Connect-Pac -EnvironmentUrl 'https://test.invalid' -ClientId 'partial' } 'all three'
Assert-Rejected { Assert-CheckerStatus @('Status: FinishedWithErrors') } 'did not report'
Assert-Rejected { Assert-CheckerStatus @('Status: Failed') } 'did not report'
Assert-Rejected { Assert-CheckerStatus @('Unrecognized output') } 'did not report'
Assert-CheckerStatus @('Checking solution', '    Status: Finished')
$count++

$environmentNames = @('PP_AUTOMATION_ENABLED', 'PP_ENVIRONMENT_URL', 'PP_TENANT_ID', 'PP_CLIENT_ID', 'PP_CLIENT_SECRET', 'GITHUB_REPOSITORY', 'GITHUB_OUTPUT')
$saved = @{}
foreach ($name in $environmentNames) { $saved[$name] = [Environment]::GetEnvironmentVariable($name) }
$temp = Join-Path ([IO.Path]::GetTempPath()) ('copilot-reliability-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $env:PP_AUTOMATION_ENABLED = ''
    Assert-Rejected { Assert-AutomationEnvironment } 'disabled'
    $env:PP_AUTOMATION_ENABLED = 'true'
    $env:PP_ENVIRONMENT_URL = ''
    Assert-Rejected { Assert-AutomationEnvironment } 'PP_ENVIRONMENT_URL is missing'
    $env:PP_ENVIRONMENT_URL = 'https://test.invalid'
    $env:PP_TENANT_ID = 'test-only'
    $env:PP_CLIENT_ID = 'test-only'
    $env:PP_CLIENT_SECRET = ''
    Assert-Rejected { Assert-AutomationEnvironment } 'PP_CLIENT_SECRET is missing'

    $solution = Join-Path $temp 'solution.zip'
    $unmanaged = Join-Path $temp 'source_unmanaged.zip'
    $settingsFile = Join-Path $temp 'settings.json'
    $templateFile = Join-Path $temp 'settings-template.json'
    $manifestFile = Join-Path $temp 'manifest.json'
    Write-TestArchive $solution '1'
    Write-TestArchive $unmanaged '0'
    $template = @{
        EnvironmentVariables = @(@{ SchemaName = 'test_Endpoint'; Value = '' })
        ConnectionReferences = @(@{ LogicalName = 'test_Connection'; ConnectionId = ''; ConnectorId = '/providers/Microsoft.PowerApps/apis/shared_test' })
    }
    $template | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $templateFile
    $settings = @{
        EnvironmentVariables = @(@{ SchemaName = 'test_Endpoint'; Value = 'https://backend.invalid' })
        ConnectionReferences = @(@{ LogicalName = 'test_Connection'; ConnectionId = 'test-connection'; ConnectorId = '/providers/Microsoft.PowerApps/apis/shared_test' })
    }
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsFile
    $manifest = @{
        SchemaVersion = 1; SolutionName = 'TestOnly'; SolutionVersion = '1.0.0.0'
        ManagedSha256 = (Get-FileHash $solution).Hash
        UnmanagedSha256 = (Get-FileHash $unmanaged).Hash
        SettingsTemplateSha256 = (Get-FileHash $templateFile).Hash
        Repository = 'test/repository'; ExportRunId = '123'; Commit = ('a' * 40)
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestFile
    $parameters = @{
        SolutionFile = $solution; ManifestFile = $manifestFile; ExpectedSolutionName = 'TestOnly'
        DeploymentSettingsFile = $settingsFile; ExpectedRunId = '123'
        ExpectedRepository = 'test/repository'; ExpectedCommit = ('a' * 40)
    }
    $validator = Join-Path $PSScriptRoot 'validate-deployment.ps1'
    & $validator @parameters
    $count++
    Assert-Rejected { & (Join-Path $PSScriptRoot 'import-agent.ps1') -TargetEnvironmentUrl 'https://test.invalid' -SolutionFile $solution -ManifestFile $manifestFile -ExpectedSolutionName 'TestOnly' -DeploymentSettingsFile $settingsFile } 'disabled without -ConfirmImport'
    Assert-Rejected { & (Join-Path $PSScriptRoot 'export-agent.ps1') -EnvironmentUrl 'https://test.invalid' -SolutionName 'TestOnly' -OutputFolder $temp } 'must not exist'
    $parameters.SolutionFile = Join-Path $root 'samples\faq-support-agent\Other\Solution.xml'
    Assert-Rejected { & $validator @parameters } 'Central Directory|archive|zip|End of Central'
    $parameters.SolutionFile = $unmanaged
    Assert-Rejected { & $validator @parameters } 'Only a managed export'
    $parameters.SolutionFile = $solution
    $parameters.ExpectedSolutionName = 'WrongName'
    Assert-Rejected { & $validator @parameters } 'Only a managed export'
    $parameters.ExpectedSolutionName = 'TestOnly'
    $parameters.ExpectedRunId = '456'
    Assert-Rejected { & $validator @parameters } 'provenance'
    $parameters.ExpectedRunId = '123'
    $manifest.ManagedSha256 = '0' * 64
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestFile
    Assert-Rejected { & $validator @parameters } 'hash mismatch'
    $manifest.ManagedSha256 = (Get-FileHash $solution).Hash
    $manifest | ConvertTo-Json | Set-Content -LiteralPath $manifestFile
    foreach ($file in @('deployment-settings.test.json', 'deployment-settings.prod.json')) {
        $parameters.DeploymentSettingsFile = Join-Path $root "config\$file"
        Assert-Rejected { & $validator @parameters } 'placeholders'
    }
    $parameters.DeploymentSettingsFile = $settingsFile
    $settings.EnvironmentVariables[0].SchemaName = 'wrong_Endpoint'
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsFile
    Assert-Rejected { & $validator @parameters } 'exactly the keys'
    $settings.EnvironmentVariables[0].SchemaName = 'test_Endpoint'
    $settings.ConnectionReferences[0].ConnectionId = ''
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsFile
    Assert-Rejected { & $validator @parameters } 'empty ConnectionId'
    $settings.ConnectionReferences[0].ConnectionId = 'test-connection'
    $settings.ConnectionReferences[0].ConnectorId = 'wrong-connector'
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsFile
    Assert-Rejected { & $validator @parameters } 'ConnectorId differs'
    $settings.ConnectionReferences[0].ConnectorId = '/providers/Microsoft.PowerApps/apis/shared_test'
    $settings.EnvironmentVariables += $settings.EnvironmentVariables[0]
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsFile
    Assert-Rejected { & $validator @parameters } 'without duplicates'

    $reports = Join-Path $temp 'reports'
    New-Item -ItemType Directory -Path $reports | Out-Null
    $checker = Join-Path $PSScriptRoot 'validate-checker-results.ps1'
    Assert-Rejected { & $checker -ResultsFolder $reports } 'did not produce'
    $report = Join-Path $reports 'result.sarif'
    '{"runs":[{"results":[{"message":{"text":"test finding"}}]}]}' | Set-Content -LiteralPath $report
    Assert-Rejected { & $checker -ResultsFolder $reports } 'zero checker findings'
    '{"runs":[{"results":[],"invocations":[{"executionSuccessful":false}]}]}' | Set-Content -LiteralPath $report
    Assert-Rejected { & $checker -ResultsFolder $reports } 'analysis failed'
    '{"runs":[{"results":[],"invocations":[{"executionSuccessful":true}]}]}' | Set-Content -LiteralPath $report
    & $checker -ResultsFolder $reports
    $count++
    $zippedReports = Join-Path $temp 'zipped-reports'
    New-Item -ItemType Directory -Path $zippedReports | Out-Null
    $zipReport = Join-Path $zippedReports 'checker-results.zip'
    [IO.Compression.ZipFile]::CreateFromDirectory($reports, $zipReport)
    & $checker -ResultsFolder $zippedReports
    $count++
    Remove-Item -LiteralPath $zipReport
    '{"runs":[{"results":[{"message":{"text":"finding inside ZIP"}}]}]}' | Set-Content -LiteralPath $report
    [IO.Compression.ZipFile]::CreateFromDirectory($reports, $zipReport)
    Assert-Rejected { & $checker -ResultsFolder $zippedReports } 'zero checker findings'
    '{"runs":[{"results":null}]}' | Set-Content -LiteralPath $report
    Assert-Rejected { & $checker -ResultsFolder $reports } 'no results array'

    # Stub gh, not PAC: no test invokes a live export, checker, import, or authentication.
    function gh {
        $global:LASTEXITCODE = 0
        $runFixture | ConvertTo-Json -Depth 5
    }
    $env:GITHUB_REPOSITORY = 'test/repository'
    $env:GITHUB_OUTPUT = Join-Path $temp 'github-output'
    $runFixture = @{
        repository = @{full_name = 'test/repository'}
        head_repository = @{full_name = 'test/repository'}
        path = '.github/workflows/export-dev-agent.yml'
        event = 'workflow_dispatch'; head_branch = 'main'; status = 'completed'
        conclusion = 'success'; head_sha = ('a' * 40)
    }
    $runValidator = Join-Path $PSScriptRoot 'validate-export-run.ps1'
    & $runValidator -RunId '123'
    $count++
    foreach ($field in @('path', 'event', 'head_branch', 'status', 'conclusion')) {
        $original = $runFixture[$field]
        $runFixture[$field] = 'wrong'
        Assert-Rejected { & $runValidator -RunId '123' } 'successful main-branch export'
        $runFixture[$field] = $original
    }
    $runFixture.head_repository.full_name = 'fork/repository'
    Assert-Rejected { & $runValidator -RunId '123' } 'successful main-branch export'
    Assert-Rejected { & $runValidator -RunId '123; injected' } 'Cannot validate argument|does not match'
} finally {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $saved[$name]) }
    Remove-Item Function:\gh -ErrorAction SilentlyContinue
    # Only the uniquely created test fixture directory is removed.
    Remove-Item -LiteralPath $temp -Recurse -Force
}

$deploy = Get-Content -LiteralPath (Join-Path $root '.github\workflows\deploy-agent.yml') -Raw
$export = Get-Content -LiteralPath (Join-Path $root '.github\workflows\export-dev-agent.yml') -Raw
Assert-True ($deploy -notmatch '(?m)^\s+push:') 'Push must not deploy solutions.'
Assert-True ($deploy -match 'default: TEST') 'Default deployment target must be TEST.'
Assert-True ($deploy -match "environment:.*'production'.*'test'") 'Explicit production environment gate is missing.'
Assert-True ($deploy -notmatch 'continue-on-error') 'Checker/import errors must block.'
Assert-True ($deploy -match 'fail-on-analysis-error: true') 'Checker analysis errors must block.'
Assert-True ($deploy -match "validate-checker-results.ps1 -ResultsFolder 'out\\checker'") 'Missing evidence and checker findings must block.'
Assert-True ($deploy -notmatch 'PP_ENVIRONMENT_URL_PROD|\|\| secrets\.') 'Environment URL must not fall back to production.'
Assert-True ($deploy -notmatch 'pack-solution|samples/') 'Deployment must not pack educational sources.'
Assert-True ($export -notmatch 'unpack-solution|git push|contents: write|solution-type: Both') 'Export must preserve artifacts without writing source branches.'
Assert-True ($export -match 'add-tools-to-path: true') 'Scripted exports require PAC on PATH.'
Assert-True ($deploy -match 'publish-changes: false' -and $deploy -match 'activate-plugins: false') 'Import must not implicitly activate workflows or claim agent publishing.'
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root '.github\workflows') -Filter '*.yml') {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($match in [regex]::Matches($text, '(?ms)^\s+(?:run|inlineScript): \|\r?\n(?<body>.*?)(?=^\s{0,6}- |\z)')) {
        Assert-True ($match.Groups['body'].Value -notmatch '\$\{\{\s*(?:github\.event\.)?inputs\.') "Untrusted input interpolated into script in $($file.Name)."
    }
}
Write-Host "$count offline reliability checks passed. No tenant integration was exercised."
