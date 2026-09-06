<#
.SYNOPSIS
Offline regression checks. Synthetic archives below are test data, never deployable samples.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'deployment-common.ps1')
$root = Split-Path -Parent $PSScriptRoot
$counter = @{ Value = 0 }
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $counter.Value++
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
$counter.Value++

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
    $counter.Value++
    Assert-Rejected { & (Join-Path $PSScriptRoot 'import-agent.ps1') -TargetEnvironmentUrl 'https://test.invalid' -SolutionFile $solution -ManifestFile $manifestFile -ExpectedSolutionName 'TestOnly' -DeploymentSettingsFile $settingsFile } 'disabled without -ConfirmImport'
    Assert-Rejected { & (Join-Path $PSScriptRoot 'export-agent.ps1') -EnvironmentUrl 'https://test.invalid' -SolutionName 'TestOnly' -OutputFolder $temp } 'must not exist'
    $parameters.SolutionFile = Join-Path $root 'samples\faq-support-agent\README.md'
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
    $placeholderSettingsFile = Join-Path $temp 'placeholder-settings.json'
    foreach ($placeholder in @('REPLACE_WITH_TARGET_ENDPOINT', 'https://contoso.com', '00000000-0000-0000-0000-000000000000')) {
        (Get-Content -LiteralPath $settingsFile -Raw).Replace('https://backend.invalid', $placeholder) |
            Set-Content -LiteralPath $placeholderSettingsFile
        $parameters.DeploymentSettingsFile = $placeholderSettingsFile
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
    $counter.Value++
    $zippedReports = Join-Path $temp 'zipped-reports'
    New-Item -ItemType Directory -Path $zippedReports | Out-Null
    $zipReport = Join-Path $zippedReports 'checker-results.zip'
    [IO.Compression.ZipFile]::CreateFromDirectory($reports, $zipReport)
    & $checker -ResultsFolder $zippedReports
    $counter.Value++
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
    $counter.Value++
    foreach ($field in @('path', 'event', 'head_branch', 'status', 'conclusion')) {
        $original = $runFixture[$field]
        $runFixture[$field] = 'wrong'
        Assert-Rejected { & $runValidator -RunId '123' } 'successful main-branch export'
        $runFixture[$field] = $original
    }
    $runFixture.head_repository.full_name = 'fork/repository'
    Assert-Rejected { & $runValidator -RunId '123' } 'successful main-branch export'
    Assert-Rejected { & $runValidator -RunId '123; injected' } 'Cannot validate argument|does not match'

    # Exercise script orchestration with a fake PAC command, never the installed CLI.
    $pacCalls = [Collections.Generic.List[string]]::new()
    $pacFailure = ''
    function pac {
        $operation = $args[0..1] -join ' '
        $pacCalls.Add($operation)
        $global:LASTEXITCODE = 0
        if ($operation -eq $pacFailure) {
            $global:LASTEXITCODE = 23
            return
        }
        switch ($operation) {
            'auth create' {}
            'solution export' {
                $pathIndex = [array]::IndexOf($args, '--path') + 1
                $managedFlag = if ($args -contains '--managed') { '1' } else { '0' }
                Write-TestArchive $args[$pathIndex] $managedFlag
            }
            'solution create-settings' {
                $settingsIndex = [array]::IndexOf($args, '--settings-file') + 1
                $template | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $args[$settingsIndex]
            }
            'solution check' {
                $outputIndex = [array]::IndexOf($args, '--outputDirectory') + 1
                New-Item -ItemType Directory -Path $args[$outputIndex] | Out-Null
                [IO.Compression.ZipFile]::CreateFromDirectory($cleanReports, (Join-Path $args[$outputIndex] 'results.zip'))
                'Status: Finished'
            }
            'solution import' {
                foreach ($flag in @('--settings-file', '--environment', '--path', '--force-overwrite', '--publish-changes', '--activate-plugins')) {
                    Assert-True ($args -contains $flag) "Local import omitted $flag."
                }
                foreach ($flag in @('--force-overwrite', '--publish-changes', '--activate-plugins')) {
                    $flagIndex = [array]::IndexOf($args, $flag) + 1
                    Assert-True ($args[$flagIndex] -ceq 'false') "Local import enabled $flag."
                }
            }
            default { throw "Unexpected test PAC operation: $operation" }
        }
    }
    $exportScript = Join-Path $PSScriptRoot 'export-agent.ps1'
    $fakeExport = Join-Path $temp 'fake-export'
    & $exportScript -EnvironmentUrl 'https://test.invalid' -SolutionName 'TestOnly' -OutputFolder $fakeExport
    Assert-True (($pacCalls -join ',') -eq 'auth create,solution export,solution export,solution create-settings') 'Export orchestration differs.'
    $pacCalls.Clear()
    $pacFailure = 'auth create'
    Assert-Rejected { & $exportScript -EnvironmentUrl 'https://test.invalid' -SolutionName 'TestOnly' -OutputFolder (Join-Path $temp 'failed-export') } 'exit code 23'
    Assert-True (($pacCalls -join ',') -eq 'auth create') 'Export continued after failed authentication.'
    $pacFailure = ''

    # Redirect only this test's checker output into its disposable fixture directory.
    $cleanReports = Join-Path $temp 'clean-reports'
    New-Item -ItemType Directory -Path $cleanReports | Out-Null
    '{"runs":[{"results":[]}]}' | Set-Content -LiteralPath (Join-Path $cleanReports 'result.sarif')
    $settings.EnvironmentVariables = @(@{ SchemaName = 'test_Endpoint'; Value = 'https://backend.invalid' })
    $settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $settingsFile
    $importParameters = @{
        TargetEnvironmentUrl = 'https://test.invalid'
        SolutionFile = (Join-Path $fakeExport 'solution.zip')
        ManifestFile = (Join-Path $fakeExport 'manifest.json')
        ExpectedSolutionName = 'TestOnly'; DeploymentSettingsFile = $settingsFile
        ConfirmImport = $true; CheckerOutputFolder = (Join-Path $temp 'local-checker')
    }
    $pacCalls.Clear()
    & (Join-Path $PSScriptRoot 'import-agent.ps1') @importParameters
    Assert-True (($pacCalls -join ',') -eq 'auth create,solution check,solution import') 'Import orchestration differs.'
    $pacCalls.Clear()
    $pacFailure = 'solution check'
    $importParameters.CheckerOutputFolder = Join-Path $temp 'failed-checker'
    Assert-Rejected { & (Join-Path $PSScriptRoot 'import-agent.ps1') @importParameters } 'exit code 23'
    Assert-True (-not $pacCalls.Contains('solution import')) 'Import continued after checker failure.'
} finally {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $saved[$name]) }
    Remove-Item Function:\gh -ErrorAction SilentlyContinue
    Remove-Item Function:\pac -ErrorAction SilentlyContinue
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
& (Join-Path $PSScriptRoot 'test-samples.ps1')
Write-Host "$($counter.Value) offline reliability checks passed. No tenant integration was exercised."
# GitHub's pwsh wrapper propagates LASTEXITCODE, including deliberately failed test commands.
exit 0
