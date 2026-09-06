# Contributing

Thanks for your interest in improving this repository.

## Scope

This repository is a **teaching and starter-kit resource** for automating Microsoft Copilot Studio deployments. It is not an official Microsoft product and is not officially supported by Microsoft.

## Before you contribute

1. Search existing issues and pull requests to avoid duplicates.
2. For anything beyond a small fix (typos, broken links), open an issue first to discuss the change.

## Making changes

1. Fork the repository and create a feature branch from `main`.
2. Keep changes focused — one topic per pull request.
3. If you change a GitHub Actions workflow, run the repository's existing relevant checks and inspect the documented upstream action inputs. Preserve manual promotion, export provenance, environment-scoped credentials, blocking checks, and separate agent publication. YAML alone cannot configure GitHub required reviewers or branch restrictions.
4. If you change Bicep or Terraform, run:
   ```powershell
   az bicep build --file infrastructure\bicep\main.bicep
   terraform '-chdir=infrastructure\terraform' validate
   ```
5. If you change PowerShell scripts, ensure they still parse:
   ```powershell
   [System.Management.Automation.Language.Parser]::ParseFile("scripts\your-script.ps1", [ref]$null, [ref]$null)
   ```
6. For deployment scripts/workflows or sample assets, run the existing offline regression checks from the repository root. Sample YAML parsing uses `powershell-yaml` version `0.4.12` (also installed by CI). If it is missing locally, install it with `Install-Module powershell-yaml -RequiredVersion 0.4.12 -Scope CurrentUser`, then run:
   ```powershell
   pwsh -NoProfile -File .\scripts\test-reliability.ps1
   ```
   These use synthetic fixtures and mocked command behavior; they do not need PAC, credentials, or a tenant. `.github\workflows\validate.yml` runs the checks on pull requests and pushes to `main`, without secrets. This validation workflow is not push-triggered deployment. Passing it does not prove real PAC compatibility, import success, checker-service behavior, or agent publication. Do not run tenant exports, imports, checker calls, provisioning, or publication without explicit authorization.
7. For capability documentation, cite current official sources and stamp the verification date. Distinguish preview/region/harness/channel limits, source grounding versus model invocation versus delegation, and proposed behavior versus tested behavior. Do not claim automatic security propagation or deployment readiness from static checks.

## Sample solution disclaimer

The editable files under `samples/it-faq-agent/` and `samples/ticket-intake-agent/` are **hand-authored UI assets**, not a real export from a Power Platform environment. The old `samples/faq-support-agent/` fake solution has been retired. Document each asset's supported destination, official schema source/license provenance, and manual expected outcomes. Never claim a submission or escalation without backend success. Do not use sample folders as deployment payloads. Export automation retains genuine managed/unmanaged archives rather than committing, unpacking, or repacking them.

Before contributing tenant-derived content, review permission to share it and remove sensitive data from a separate illustrative copy. Clearly label redacted source as illustrative: changing real component IDs inside a deployment archive breaks its integrity/provenance and can make it unusable. Never publish credentials or private tenant content.

## Code of conduct

Be respectful and constructive. Issues or PRs that are abusive or off-topic will be closed.
