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
3. If you change a GitHub Actions workflow, validate the YAML locally (for example with `actionlint` or the VS Code GitHub Actions extension) before submitting.
4. If you change Bicep or Terraform, run:
   ```powershell
   az bicep build --file infrastructure/bicep/main.bicep
   terraform -chdir=infrastructure/terraform validate
   ```
5. If you change PowerShell scripts, ensure they still parse:
   ```powershell
   [System.Management.Automation.Language.Parser]::ParseFile("scripts\your-script.ps1", [ref]$null, [ref]$null)
   ```

## Sample solution disclaimer

The files under `samples/faq-support-agent/` are **hand-authored templates**, not a real export from a Power Platform environment. If you contribute a real exported solution (via `pac solution export` + `pac solution unpack`), please note that clearly in your pull request description and remove any tenant-specific identifiers (GUIDs, connection references, environment URLs) first.

## Code of conduct

Be respectful and constructive. Issues or PRs that are abusive or off-topic will be closed.
