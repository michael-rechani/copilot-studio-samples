# 02: ALM and explicit artifact promotion

**Documentation review: 2026-09-05.** These workflows are a guarded starter pattern, not a tenant-tested production pipeline. They do not prove solution compatibility, connection authorization, agent behavior, or live-channel readiness.

## Release contract

```text
Dev unmanaged solution
  -> main-only workflow_dispatch export (development GitHub environment)
  -> solution-export artifact: genuine managed + unmanaged archives, settings template, manifest
  -> reviewed target settings committed separately
  -> main-only workflow_dispatch promotion: TEST default, PROD explicitly
  -> trusted export origin + metadata/hashes/settings validation
  -> blocking solution checker
  -> import original managed ZIP
  -> separate target agent publication, activation decisions, and live validation
```

There is **no push-triggered solution deployment**, no automatic Dev-export commit/push, and no unpack/repack in this path. Do not turn the hand-authored sample into a “managed” package. Merely changing package type cannot establish a genuine managed export.

### Managed does not mean immutable or reversible

Develop in an unmanaged solution and promote genuine managed exports downstream. Managed properties and solution layers influence which customizations are allowed; managed import does not universally lock every component or remove existing unmanaged layers. Uninstall can be blocked by dependencies and can remove data/components. Rollback is not guaranteed by importing an older ZIP. Test the chosen upgrade/recovery path, retain backups and evaluated artifacts, and avoid unreviewed force-overwrite behavior.

Dev is the authoring source for this export-based path; the retained artifact is the exact release payload. Human-readable source review can be a separate process, but must not replace or silently rebuild the managed payload being promoted.

## GitHub environments and credentials

Follow [the setup checklist](00-first-time-setup-checklist.md) **before storing credentials**.

| GitHub environment | Workflow/target | Required environment secrets |
|---|---|---|
| `development` | Dev export | `PP_ENVIRONMENT_URL`, `PP_TENANT_ID`, `PP_CLIENT_ID`, `PP_CLIENT_SECRET` |
| `test` | `target_environment: TEST` | Same names, separate Test values |
| `production` | `target_environment: PROD` | Same names, separate Prod values |

Do not define these four names in repository or organization secrets as fallback values. GitHub resolves secret names by scope; workflow YAML cannot prove that a value came from an environment rather than a broader scope. Administrators must verify that broader fallback definitions are absent.

Configure **required reviewers and deployment branch restrictions for production in GitHub Settings → Environments**. Restrict to `main`, protect reviewed changes, and decide self-review/admin-bypass policy. YAML naming `production` does not install those settings. Verify the repository's GitHub plan supports the protections; if not, leave production automation disabled and credentials absent.

Only after settings and least-privilege application users are reviewed, add the environment secrets and set the environment variable **`PP_AUTOMATION_ENABLED=true`**. The flag acknowledges setup; it does not inspect GitHub protection rules. Separate deployment identities prevent an identity intended for Dev/Test from being an implicit Prod credential. A Dataverse application user is not human delegated impersonation.

## 1. Export from real Dev

Manually dispatch **Export Copilot Solution from Dev** (`export-dev-agent.yml`) from `main` with `solution_name`, the solution's **unique name**, not its friendly display name or a folder path.

The workflow exports to a fresh directory and uploads one **`solution-export`** Actions artifact:

| File | Meaning |
|---|---|
| `solution.zip` | Genuine managed export from Dev, the only import payload |
| `source_unmanaged.zip` | Unmanaged export of the same solution/version, retained for review/recovery |
| `settings-template.json` | Generated from the managed archive using `pac solution create-settings` |
| `manifest.json` | `SchemaVersion`, `SolutionName`, `SolutionVersion`, `ManagedSha256`, `UnmanagedSha256`, `SettingsTemplateSha256`, `Repository`, `ExportRunId`, `Commit` |

Freeze edits during export and review the result: the two exports are sequential, and equal solution versions do not prove no one changed content between calls. A manifest hash establishes consistency with that manifest, **not authenticity**: someone able to replace both files could recompute the hashes. Provenance relies separately on verifying the successful same-repository main-branch export workflow and its run/commit, protecting the workflow and branch, and restricting access to the GitHub environments and their credentials. This is not a cryptographic signature or independent artifact attestation.

The workflow does not commit/push, unpack, or repack. Treat artifacts as sensitive configuration: restrict access, protect workflow changes, and apply approved retention. The current export retention is **30 days**. Promote before expiration or retain an approved release record/archive; do not substitute a ZIP from an unrelated run if the artifact is gone.

### Optional local export

Install a supported Power Platform CLI and verify its help/version before use. From the repository root, an authorized operator can run:

```powershell
.\scripts\export-agent.ps1 `
  -EnvironmentUrl "https://your-dev.crm.dynamics.com" `
  -SolutionName "FAQSupportAgent"
```

This authenticates to the explicit environment (interactive if no service-principal credentials are supplied), exports both archives, and generates settings/manifest into **`out\export` by default**. That output folder must not already exist; use a new `-OutputFolder` for another export rather than mixing old files. Never pass the sample source folder as an output destination.

Optional `-TenantId`, `-ClientId`, and `-ClientSecret` must be provided together when using application credentials. Inject credentials securely; do not paste them into committed scripts or shell history. A local manifest does not provide the trusted GitHub export-run provenance required by the promotion workflow.

## 2. Prepare reviewed deployment settings

Start with `settings-template.json` from **this export**, not a generic JSON example. To regenerate a draft locally from the managed archive:

```powershell
pac solution create-settings `
  --solution-zip ".\out\export\solution.zip" `
  --settings-file ".\out\export\settings-draft.json"
```

Populate the correct **existing target** connection IDs, connector IDs, and environment-variable values in separately reviewed:

- `config\deployment-settings.test.json`
- `config\deployment-settings.prod.json`

The validator requires the exact environment-variable schema names and connection-reference logical names from the exported template, without duplicate/missing/extra keys. Values and connection IDs must be nonempty; connector IDs must match the exported references. Placeholders (`REPLACE_`, `contoso`, zero GUID examples) deliberately block deployment. This conservative sample policy can reject intentional empty values; change such policy only in a reviewed implementation, not by inventing a value.

Settings do not create connections, grant permissions, establish ownership, or validate downstream authorization. Review those in the target environment. Do not store passwords, API keys, or client secrets in settings or export review notes. See [config guidance](../config/README.md) and [Microsoft's deployment-settings documentation](https://learn.microsoft.com/en-us/power-platform/alm/conn-ref-env-variables-build-tools).

## 3. Promote the chosen export

Manually dispatch **Promote Copilot Solution** (`deploy-agent.yml`) from `main`:

| Input | Value |
|---|---|
| `target_environment` | `TEST` by default; explicitly select `PROD` only after Test evidence |
| `export_run_id` | Successful main-branch export workflow run ID in this same repository |
| `solution_name` | Expected unique solution name in that artifact |

The promotion checks:

1. The selected run belongs to the approved export workflow in the same repository, succeeded, and ran on `main`.
2. The downloaded `solution-export` bundle matches expected run/repository/commit provenance.
3. The managed ZIP has the expected solution name/version and managed flag; all bundle hashes match; the unmanaged archive has the corresponding name/version and unmanaged flag.
4. Reviewed target settings match the generated template.
5. The solution checker completes successfully with acceptable findings before import.

The target settings are checked out from the promotion run's reviewed `main` revision. Record that revision as well as the **export** commit: they can differ intentionally because settings are reviewed after export.

### The solution checker is a gate, not a report-only step

The workflow uses **`microsoft/powerplatform-actions/check-solution@v1`** with **`fail-on-analysis-error: true`** and then downloads the **`solution-checker`** artifact to validate its evidence. This action version does **not** expose error-level or per-rule threshold inputs: its [implementation](https://github.com/microsoft/powerplatform-actions/blob/v1/src/actions/check-solution/index.ts), verified 2026-09-05, hardcodes `HighIssueCount` with threshold `0`, not a threshold for all severities. The repository's separate `validate-checker-results.ps1` requires a present, valid SARIF report with zero results/findings and no failed analysis invocation. Missing/malformed evidence or any finding blocks import. This deliberately conservative **zero-findings** policy includes low/informational findings; it is stricter than the upstream action's high-issue threshold. Do not infer that `fail-on-analysis-error` alone enforces a findings threshold.

The local import path also runs PAC solution checker and checks completion/report evidence. The validator reads both PAC's ZIP-contained SARIF and the GitHub action's loose/extracted SARIF reports; it reads archive entries without extracting archive-supplied paths. Local import additionally requires the textual PAC summary `Status: Finished`; unknown, failed, or incomplete summaries fail closed. Current live PAC output has not been verified here, so a future CLI output-format change may require a reviewed parser update—not bypassing the gate. Offline regressions cover both report forms, not the live service.

The checker is a service call against the configured environment and may require additional privileges/availability. It is not an offline safety test and not a replacement for agent quality, permissions, tool behavior, or channel tests.

Import uses the **original managed ZIP** and reviewed target settings with `force-overwrite: false`, `publish-changes: false`, and `activate-plugins: false`. There is no automatic customizations publishing, agent publishing, or plugin/flow activation. If validation or checker fails, fix the source/settings/permissions and repeat with an appropriate reviewed export. Do not skip the gate to “see if import works.”

## 4. Local validation and import — different trust boundary

Offline validation needs the whole export bundle together because the manifest references the unmanaged archive and generated settings template:

```powershell
.\scripts\validate-deployment.ps1 `
  -SolutionFile ".\out\export\solution.zip" `
  -ManifestFile ".\out\export\manifest.json" `
  -DeploymentSettingsFile ".\config\deployment-settings.test.json" `
  -ExpectedSolutionName "FAQSupportAgent"
```

This makes no tenant call. Passing it proves only the implemented archive/settings checks, not connection existence, tenant compatibility, or authorization.

**A local import bypasses GitHub environment approval gates.** It must be separately authorized; it is not a way around required reviewers. `-ConfirmImport` is explicit operator consent, not external approval.

Only an authorized operator who intends to modify the target should run:

```powershell
.\scripts\import-agent.ps1 `
  -SolutionFile ".\out\export\solution.zip" `
  -ManifestFile ".\out\export\manifest.json" `
  -DeploymentSettingsFile ".\config\deployment-settings.test.json" `
  -ExpectedSolutionName "FAQSupportAgent" `
  -TargetEnvironmentUrl "https://your-test.crm.dynamics.com" `
  -ConfirmImport
```

All five named file/name/target parameters are mandatory; import is disabled without the explicit switch. The script checks the existing bundle before authentication, then authenticates to the specified target, runs the blocking checker, and imports—never packages sample source. Checker evidence goes into a fresh unique folder under `out` by default; an optional `-CheckerOutputFolder` must also name a nonexistent directory so stale reports cannot authorize an import. A local caller controls its input files and lacks the workflow's trusted-run origin gate; hashes alone do not establish GitHub provenance.

## 5. Publication and live validation are separate release operations

After import, verify agent dependencies, knowledge readiness, connections/owners, runtime authentication, and any flows that need separate approved activation. Then publish the **intended target agent** manually in Copilot Studio using **Publish**, or use the documented CLI with an explicitly verified target bot ID:

```powershell
pac copilot publish `
  --bot "<TARGET-BOT-ID>" `
  --environment "https://your-test.crm.dynamics.com"
```

This is a mutating operation for an authorized operator, **not executed by this workflow**. The supported syntax is documented in [PAC copilot publish](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/copilot#pac-copilot-publish). Resolve/verify the bot in the target; do not blindly reuse a Dev ID.

**`pac solution publish` publishes Dataverse customizations; it is not `pac copilot publish` and does not by itself publish/activate the conversational agent.** Do not equate a successful solution import with a live agent update.

Publish first to a restricted audience, open a **new session in the actual channel**, and test sign-in, citations, tools, confirmation, failure handling, conversation isolation, and target configuration. Existing sessions can continue using prior content. The maker test pane is not sufficient evidence. See [official publication guidance](https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-fundamentals-publish-channels) and the [repeatable IT support cases](05-it-support-reference-walkthrough.md#7-repeatable-evaluation-before-release).

Record approval, export run/hash/version, settings revision, checker evidence, target bot/published version, Foundry version if relevant, test results, monitoring owner, and recovery plan. Repeat the explicit promotion/publication/evaluation process for Prod using the **same evaluated export**.

## Evidence and recovery limits

No tenant export/import, checker service execution, live publication, or conversational evaluation is claimed by this documentation. PAC was not installed in the local environment used for this revision; source/schema inspection and mocked synthetic fixtures are not real PAC validation.

Contributors can run the existing offline checks without PAC or credentials:

```powershell
pwsh -NoProfile -File .\scripts\test-reliability.ps1
```

`validate.yml` runs these checks on pull requests and pushes to `main`, without secrets. That CI trigger is validation only, not a solution deployment. Offline fixtures and static checks cannot establish runtime success.

On a failed/uncertain import, inspect its target-side status before retrying. On a bad publication, restrict access or use an approved recovery procedure; do not assume reimporting an old version is supported rollback. Backups, dependencies, retained data, external tickets, and Azure resources require their own recovery decisions.

Official references reviewed **2026-09-05**:

- [PAC solution commands](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/solution)
- [Deployment settings](https://learn.microsoft.com/en-us/power-platform/alm/conn-ref-env-variables-build-tools)
- [PAC copilot publish](https://learn.microsoft.com/en-us/power-platform/developer/cli/reference/copilot#pac-copilot-publish)
- [Publish and deploy agents](https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-fundamentals-publish-channels)
- [GitHub deployment environments and protection configuration](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
