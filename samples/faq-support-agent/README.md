# ⚠️ Template Sample — Not a Real Export

The files in this folder (`Other/`, `src/`) are **hand-authored templates** meant to illustrate the shape and structure of an unpacked Copilot Studio / Dataverse solution. They are **not** the output of a real `pac solution export` + `pac solution unpack` run, and they will likely **fail to import** into an actual Power Platform environment as-is because they are missing real component GUIDs, complete entity metadata, and other Dataverse-generated identifiers.

## What this is useful for

- Learning the folder layout and file naming conventions Copilot Studio solutions use once unpacked.
- Seeing example Power Fx expressions, topic trigger phrases, and adaptive dialog structure.
- Having a starting point to diff against once you export your own real solution.

## What this is NOT

- A production-ready or importable Copilot Studio agent.
- An officially supported Microsoft sample.

## How to replace this with a real solution

1. Build your agent in a Power Platform **Dev** environment using Copilot Studio.
2. Add it to a Dataverse solution.
3. Export and unpack it using the included script:
   ```powershell
   cd scripts
   .\export-agent.ps1 -EnvironmentUrl "https://your-org-dev.crm.dynamics.com" -SolutionName "FAQSupportAgent"
   ```
4. Replace the contents of this folder with the real unpacked output.
5. Remove any tenant-specific identifiers before committing to a public repository.

See [`docs/00-first-time-setup-checklist.md`](../../docs/00-first-time-setup-checklist.md) for the full walkthrough.
