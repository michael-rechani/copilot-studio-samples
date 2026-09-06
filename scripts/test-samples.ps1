<#
.SYNOPSIS
Offline sample parsing and invariants, not tenant schema validation or Power Fx execution.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module powershell-yaml -RequiredVersion 0.4.12 -ErrorAction Stop
$sampleRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'samples'
$checks = 0
function Assert-Sample {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:checks++
}
function Get-SampleNodes {
    param($Value)
    if ($Value -is [Collections.IDictionary]) {
        if ($Value.Contains('kind')) { $Value }
        foreach ($child in $Value.Values) { Get-SampleNodes $child }
    } elseif ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        foreach ($child in $Value) { Get-SampleNodes $child }
    }
}
function Assert-LocalReferences {
    param($Value, $Definitions)
    if ($Value -is [Collections.IDictionary]) {
        if ($Value.Contains('$ref')) {
            $ref = $Value['$ref']
            Assert-Sample ($ref -match '^#/definitions/[^/]+$') "Unexpected schema reference: $ref"
            Assert-Sample ($Definitions.Contains(($ref -replace '^#/definitions/', ''))) "Unresolved schema reference: $ref"
        }
        foreach ($child in $Value.Values) { Assert-LocalReferences $child $Definitions }
    } elseif ($Value -is [Collections.IEnumerable] -and $Value -isnot [string]) {
        foreach ($child in $Value) { Assert-LocalReferences $child $Definitions }
    }
}

$topics = @{}
foreach ($name in @('it-faq-agent', 'ticket-intake-agent')) {
    $folder = Join-Path $sampleRoot $name
    $readme = Get-Content -LiteralPath (Join-Path $folder 'README.md') -Raw
    $instructions = Get-Content -LiteralPath (Join-Path $folder 'instructions.txt') -Raw
    Assert-Sample ($instructions -match 'password' -and $instructions -match 'personal information') "$name needs data minimization instructions."
    Assert-Sample ($readme -match 'untested' -and $readme -match 'genuine') "$name must disclose tenant/promotion limits."
    foreach ($match in [regex]::Matches($readme, '\]\((?<target>[^)#]+)(?:#[^)]*)?\)')) {
        $target = $match.Groups['target'].Value
        if ($target -notmatch '^https://') {
            Assert-Sample (Test-Path -LiteralPath (Join-Path $folder $target.Replace('/', '\'))) "Broken sample link: $name/$target"
        }
    }
    $examples = @(Get-Content -LiteralPath (Join-Path $folder 'examples.json') -Raw | ConvertFrom-Json)
    Assert-Sample ($examples.Count -ge 6) "$name needs positive and negative manual examples."
    Assert-Sample (@($examples.id | Select-Object -Unique).Count -eq $examples.Count) "$name has duplicate example IDs."
    foreach ($example in $examples) {
        Assert-Sample ($example.utterances.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($example.expected)) "Incomplete example: $($example.id)"
    }
    $files = @(Get-ChildItem -LiteralPath (Join-Path $folder 'topics') -Filter '*.yaml')
    Assert-Sample ($files.Count -eq 1) "$name should have one standalone topic."
    $text = Get-Content -LiteralPath $files[0].FullName -Raw
    $topic = ConvertFrom-Yaml $text
    Assert-Sample ($topic.kind -ceq 'AdaptiveDialog' -and $topic.beginDialog.kind -ceq 'OnRecognizedIntent') "$name has an unexpected topic/trigger."
    Assert-Sample ($topic.beginDialog.intent.triggerQueries.Count -ge 3) "$name needs trigger phrases."
    $nodes = @(Get-SampleNodes $topic)
    $ids = @($nodes | Where-Object { $_.Contains('id') } | ForEach-Object { $_.id })
    Assert-Sample (@($ids | Select-Object -Unique).Count -eq $ids.Count) "$name has duplicate node IDs."
    foreach ($node in $nodes) {
        Assert-Sample ($node.kind -cin @('AdaptiveDialog', 'OnRecognizedIntent', 'SetVariable', 'Question', 'ConditionGroup', 'SendActivity')) "$name contains an unreviewed node kind: $($node.kind)"
    }
    Assert-Sample ($text -notmatch '(?m)^\s*(flowId|aIModelId|dialog|knowledgeSources):|https?://') "$name must not depend on fabricated resources or knowledge schemas."
    $topics[$name] = $topic
}

$faq = Get-Content -LiteralPath (Join-Path $sampleRoot 'it-faq-agent\knowledge\approved-it-faq.md') -Raw
$faqCases = Get-Content -LiteralPath (Join-Path $sampleRoot 'it-faq-agent\examples.json') -Raw | ConvertFrom-Json
foreach ($case in $faqCases) {
    Assert-Sample ($faq -match [regex]::Escape($case.knowledgeId)) "Unknown FAQ reference: $($case.knowledgeId)"
}
Assert-Sample ($faq -match 'Fictional training organization' -and $faq -notmatch 'https?://') 'FAQ must remain fictional without invented live endpoints.'
$faqInstructions = Get-Content -LiteralPath (Join-Path $sampleRoot 'it-faq-agent\instructions.txt') -Raw
Assert-Sample ($faqInstructions -notmatch 'citation|reference') 'Do not override system citation formatting in instructions.'
Assert-Sample ($topics['it-faq-agent'].beginDialog.actions.Count -eq 1) 'FAQ scope topic must not simulate retrieval or actions.'

$draft = $topics['ticket-intake-agent']
$nodes = @(Get-SampleNodes $draft)
$byId = @{}
foreach ($node in $nodes) {
    if ($node.Contains('id')) { $byId[$node.id] = $node }
}
Assert-Sample (($draft.beginDialog.actions.id -join ',') -ceq 'resetSummary,resetCategory,resetConfirmation,askSummary,validateSummary') 'Draft must reset inputs before collecting them.'
foreach ($variable in @('Summary', 'Category', 'Confirmation')) {
    $reset = $byId["reset$variable"]
    Assert-Sample ($reset.variable -ceq "Topic.$variable" -and $reset.value -ceq '=Blank()') "Must reset $variable on every invocation."
    $question = $byId["ask$variable"]
    Assert-Sample ($question.variable -ceq "Topic.$variable" -and $question.entity -ceq 'StringPrebuiltEntity') "Unexpected question binding/entity: $variable"
}
$summaryBranch = $byId['validateSummary'].conditions[0]
Assert-Sample ($summaryBranch.condition -ceq '=!IsBlank(Trim(Topic.Summary)) && Len(Topic.Summary) <= 200 && Lower(Trim(Topic.Summary)) <> "cancel"') 'Summary must be nonblank, bounded, and cancelable.'
Assert-Sample (($summaryBranch.actions.id -join ',') -ceq 'askCategory,validateCategory') 'Category must be inside summary validation.'
$categoryBranch = $byId['validateCategory'].conditions[0]
Assert-Sample ($categoryBranch.condition -ceq '=Topic.Category = "hardware" || Topic.Category = "software" || Topic.Category = "access"') 'Category allowlist changed.'
Assert-Sample (($categoryBranch.actions.id -join ',') -ceq 'previewDraft,askConfirmation,confirmDraft') 'Must preview and ask before confirmation.'
$confirmBranch = $byId['confirmDraft'].conditions[0]
Assert-Sample ($confirmBranch.condition -ceq '=Topic.Confirmation = "confirm"') 'Only explicit confirm may reach the confirmed draft.'
Assert-Sample ($confirmBranch.actions.Count -eq 1 -and $confirmBranch.actions[0].id -ceq 'showConfirmedDraft') 'Confirmed branch must only show a draft.'
Assert-Sample ($byId['showConfirmedDraft'].activity -match '^Confirmed draft only\.') 'Do not claim submission on confirmation.'
foreach ($id in @('previewDraft', 'showConfirmedDraft', 'cancelSummary', 'cancelCategory', 'cancelConfirmation')) {
    Assert-Sample ($byId[$id].activity -match 'No ticket has been created') "Missing no-ticket disclosure in $id."
}
foreach ($pair in @(@('validateSummary', 'cancelSummary'), @('validateCategory', 'cancelCategory'), @('confirmDraft', 'cancelConfirmation'))) {
    $elseActions = $byId[$pair[0]].elseActions
    Assert-Sample ($elseActions.Count -eq 1 -and $elseActions[0].id -ceq $pair[1]) "Missing fail-closed branch: $($pair[0])"
}
$definedVariables = @($nodes | Where-Object { $_.kind -ceq 'SetVariable' } | ForEach-Object { $_.variable })
$topicText = Get-Content -LiteralPath (Join-Path $sampleRoot 'ticket-intake-agent\topics\draft-ticket.yaml') -Raw
foreach ($match in [regex]::Matches($topicText, 'Topic\.[A-Za-z]+')) {
    Assert-Sample ($match.Value -cin $definedVariables) "Undefined topic variable: $($match.Value)"
}

$contract = Get-Content -LiteralPath (Join-Path $sampleRoot 'ticket-intake-agent\connector\lab-tickets.swagger.json') -Raw | ConvertFrom-Json -AsHashtable
Assert-Sample ($contract.swagger -ceq '2.0') 'Custom connector must use OpenAPI 2.0.'
Assert-Sample ($contract.host -ceq 'tickets.example.invalid' -and $contract.basePath -ceq '/lab') 'Lab contract must not point at a live service.'
Assert-Sample (($contract.schemes -join ',') -ceq 'https' -and $contract.security.Count -eq 0) 'Unexpected lab transport/auth configuration.'
Assert-Sample ($contract.paths.Count -eq 1 -and $contract.paths['/tickets'].Count -eq 1) 'Contract must remain one operation.'
$operation = $contract.paths['/tickets'].post
Assert-Sample ($operation.operationId -ceq 'CreateLabTicket') 'Operation ID must match the setup guide.'
Assert-Sample ($operation.parameters.Count -eq 1 -and $operation.parameters[0].required -and $operation.parameters[0].in -ceq 'body') 'Missing required body parameter.'
Assert-Sample (($operation.responses.Keys | Sort-Object) -join ',' -ceq '201,400,503') 'Explicit success/validation/unavailable responses required.'
Assert-LocalReferences $contract $contract.definitions
foreach ($definition in $contract.definitions.Values) {
    Assert-Sample ($definition.type -ceq 'object') 'Contract definitions must describe objects.'
    foreach ($required in $definition.required) {
        Assert-Sample ($definition.properties.Contains($required)) "Required property is undefined: $required"
    }
}
$request = $contract.definitions.CreateLabTicketRequest
Assert-Sample (($request.required -join ',') -ceq 'summary,category,confirmed') 'Request must require summary/category/confirmation.'
Assert-Sample ($request.properties.summary.minLength -eq 1 -and $request.properties.summary.maxLength -eq 200) 'Request summary bounds must match topic.'
Assert-Sample (($request.properties.category.enum -join ',') -ceq 'hardware,software,access') 'Request categories must match topic.'
Assert-Sample ($request.properties.confirmed.type -ceq 'boolean' -and $request.properties.confirmed.enum.Count -eq 1 -and $request.properties.confirmed.enum[0] -is [bool] -and $request.properties.confirmed.enum[0]) 'Contract must require explicit true confirmation.'
$response = $contract.definitions.LabTicket
Assert-Sample (($response.required -join ',') -ceq 'ticketId,status,summary,category' -and $response.properties.ticketId.minLength -eq 1) 'Success needs a nonempty backend ID and status.'
Assert-Sample (($response.properties.status.enum -join ',') -ceq 'created') 'Unexpected backend success status.'
Assert-Sample (@(Get-ChildItem -LiteralPath $sampleRoot -Recurse -File -Filter '*.xml').Count -eq 0) 'Do not reintroduce fake solution metadata.'
Write-Host "$checks sample checks passed. YAML/JSON parsed; no tenant or Power Fx runtime exercised."
