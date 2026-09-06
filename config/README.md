# Deployment settings — reviewed for each real export

`deployment-settings.test.json` and `deployment-settings.prod.json` are **deliberately blocked placeholders**, not deployable defaults. They are selected by the manual promotion workflow for `TEST` and `PROD`, respectively. Neither JSON file contains deployment credentials or creates a runtime connection.

## Prepare the files

1. Export a real Dev solution using `export-dev-agent.yml` from `main`. Download its entire `solution-export` artifact.
2. Use that bundle's **`settings-template.json`**, generated with `pac solution create-settings`, as the shape for each target file. Do not assume the illustrative `cr123_*` names in this folder exist in your solution.
3. Obtain target-specific environment-variable values and **existing target connection IDs**. Verify connection ownership/sharing, connector identity, user-versus-maker authentication, and downstream permissions separately.
4. Populate the two files separately and review them through a protected pull request. Keep the exact exported `SchemaName` / `LogicalName` sets, without duplicates/missing/extra entries, and preserve the exported `ConnectorId`.
5. Run offline validation against the same complete export bundle before dispatching promotion.

For a local export under `out\export`, a draft can be generated without importing:

```powershell
pac solution create-settings `
  --solution-zip ".\out\export\solution.zip" `
  --settings-file ".\out\export\settings-draft.json"

.\scripts\validate-deployment.ps1 `
  -SolutionFile ".\out\export\solution.zip" `
  -ManifestFile ".\out\export\manifest.json" `
  -ExpectedSolutionName "FAQSupportAgent" `
  -DeploymentSettingsFile ".\config\deployment-settings.test.json"
```

Keep `source_unmanaged.zip` and `settings-template.json` beside `manifest.json`; the validator checks their hashes too. The validator rejects missing/blank required values and illustrative `REPLACE_`, `contoso`, and zero-GUID placeholders. Intentional empty values need an explicitly reviewed policy change, not a fabricated setting. Successful offline validation does **not** prove target connections exist or are authorized.

## Credentials and approvals are elsewhere

Never store passwords, client secrets, API keys, or tokens in these files. Use approved connections/secret stores. GitHub environments **`development`**, **`test`**, and **`production`** each require separate values for the same environment-secret names: `PP_ENVIRONMENT_URL`, `PP_TENANT_ID`, `PP_CLIENT_ID`, `PP_CLIENT_SECRET`. Do not provide repository/organization fallback secrets with those names.

Configure production required reviewers and branch restrictions in GitHub settings **before adding credentials or setting the environment's `PP_AUTOMATION_ENABLED=true`**. YAML does not configure those rules. The settings JSON does not choose the Dataverse environment: the target workflow environment secret or explicit local `-TargetEnvironmentUrl` does.

See [ALM and local import warnings](../docs/02-alm-and-automation.md). Local imports bypass GitHub approval gates even when using these reviewed settings.

Official guidance checked **2026-09-05**: [Pre-populate connection references and environment variables](https://learn.microsoft.com/en-us/power-platform/alm/conn-ref-env-variables-build-tools).
