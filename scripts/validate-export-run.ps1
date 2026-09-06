[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[1-9][0-9]*$')][string]$RunId)
. (Join-Path $PSScriptRoot 'deployment-common.ps1')
if ($env:GITHUB_REPOSITORY -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw 'Missing repository context.' }
$run = Invoke-NativeCommand gh @('api', "repos/$env:GITHUB_REPOSITORY/actions/runs/$RunId") | ConvertFrom-Json
if ($run.repository.full_name -cne $env:GITHUB_REPOSITORY -or
    $run.head_repository.full_name -cne $env:GITHUB_REPOSITORY -or
    $run.path -cne '.github/workflows/export-dev-agent.yml' -or
    $run.event -ne 'workflow_dispatch' -or $run.head_branch -ne 'main' -or
    $run.status -ne 'completed' -or $run.conclusion -ne 'success') {
    throw 'Only a successful main-branch export workflow run in this repository can be promoted.'
}
if ($run.head_sha -notmatch '^[a-f0-9]{40}$') { throw 'Invalid export commit.' }
"commit=$($run.head_sha)" >> $env:GITHUB_OUTPUT
