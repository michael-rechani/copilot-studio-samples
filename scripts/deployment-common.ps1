Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-NativeCommand {
    param([Parameter(Mandatory)][string]$Command, [string[]]$Arguments = @())
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        # Do not include arguments: authentication commands can contain credentials.
        throw "$Command failed with exit code $LASTEXITCODE."
    }
}

function Assert-EnvironmentUrl {
    param([string]$Url)
    $uri = $null
    if (-not [uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -ne 'https' -or $uri.UserInfo -or $uri.Query -or $uri.Fragment -or
        $uri.AbsolutePath -ne '/') {
        throw 'An explicit HTTPS environment origin URL is required.'
    }
}

function Assert-AutomationEnvironment {
    if ($env:PP_AUTOMATION_ENABLED -cne 'true') {
        throw 'Automation is disabled. Configure environment protections, credentials, and PP_AUTOMATION_ENABLED=true first.'
    }
    foreach ($name in @('PP_ENVIRONMENT_URL', 'PP_TENANT_ID', 'PP_CLIENT_ID', 'PP_CLIENT_SECRET')) {
        if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
            throw "Required environment secret $name is missing."
        }
    }
    Assert-EnvironmentUrl $env:PP_ENVIRONMENT_URL
}

function Connect-Pac {
    param([string]$EnvironmentUrl, [string]$TenantId, [string]$ClientId, [string]$ClientSecret)
    $provided = @($TenantId, $ClientId, $ClientSecret | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    if ($provided -notin @(0, 3)) { throw 'Provide all three SPN credentials or none for interactive authentication.' }
    if ($provided -eq 3) {
        Invoke-NativeCommand pac @('auth', 'create', '--environment', $EnvironmentUrl, '--tenant', $TenantId, '--applicationId', $ClientId, '--clientSecret', $ClientSecret)
    } else {
        Invoke-NativeCommand pac @('auth', 'create', '--environment', $EnvironmentUrl)
    }
}

function Assert-CheckerStatus {
    param([string[]]$OutputLines)
    # PAC's textual summary is also used by the upstream action; unknown output fails closed.
    $statuses = @($OutputLines | Select-String '^\s*Status\s*:\s*(\S+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    if ($statuses.Count -eq 0 -or @($statuses | Where-Object { $_ -cne 'Finished' }).Count -gt 0) {
        throw 'Checker did not report a completed Finished analysis. Review its output before importing.'
    }
}

function Get-SolutionMetadata {
    param([Parameter(Mandatory)][string]$Path)
    $archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Path).Path)
    try {
        $entries = @($archive.Entries | Where-Object { $_.FullName -ieq 'solution.xml' })
        if ($entries.Count -ne 1) { throw 'Expected exactly one root solution.xml in a real solution archive.' }
        $settings = [Xml.XmlReaderSettings]::new()
        $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
        $settings.XmlResolver = $null
        $settings.MaxCharactersInDocument = 10MB
        $stream = $entries[0].Open()
        try {
            $reader = [Xml.XmlReader]::Create($stream, $settings)
            try {
                $xml = [Xml.XmlDocument]::new()
                $xml.XmlResolver = $null
                $xml.Load($reader)
            } finally { $reader.Dispose() }
        } finally { $stream.Dispose() }
        $manifest = $xml.SelectSingleNode('/ImportExportXml/SolutionManifest')
        if ($null -eq $manifest) { throw 'Missing solution manifest.' }
        foreach ($field in @('UniqueName', 'Version', 'Managed')) {
            if (-not $manifest.SelectSingleNode($field).InnerText) { throw "Missing manifest field $field." }
        }
        return @{
            Name = $manifest.UniqueName
            Version = $manifest.Version
            Managed = $manifest.Managed
        }
    } finally { $archive.Dispose() }
}
