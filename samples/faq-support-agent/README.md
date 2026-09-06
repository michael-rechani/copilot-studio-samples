# Illustrative sample — not an importable agent

The `Other` and `src` files are **hand-authored teaching examples**, not the output of a real PAC export. They omit Dataverse-generated component IDs/metadata and do not establish a valid standalone solution or supported serialized schema.

**Do not pack/import this folder.** No pipeline in this repository should promote it, and changing a package's managed flag does not make it a genuine managed export. The files are not a production-ready agent or an officially supported Microsoft sample.

Use them only to discuss topic logic and possible source-file shapes. Actual exported layouts depend on the tool/version and components. The [beginner IT support walkthrough](../../docs/05-it-support-reference-walkthrough.md) is also illustrative: it explains knowledge Q&A, a confirmed ticket tool, and optional preview Foundry delegation, but is not implemented by these files and has not been tenant-tested.

## Build your own deployable agent

1. In a Dev Power Platform environment, build the agent in Copilot Studio and add it plus solution-aware dependencies to an unmanaged Dataverse solution.
2. Follow the [setup checklist](../../docs/00-first-time-setup-checklist.md), including protected GitHub environments before credentials.
3. Export the real solution with the main-branch `export-dev-agent.yml` workflow, or from the repository root:

   ```powershell
   .\scripts\export-agent.ps1 `
     -EnvironmentUrl "https://your-dev.crm.dynamics.com" `
     -SolutionName "FAQSupportAgent"
   ```

4. The local default is a **fresh `out\export`** containing managed `solution.zip`, `source_unmanaged.zip`, `settings-template.json`, and `manifest.json`. It does **not** unpack into or replace this sample directory.
5. Review target settings against that export, then use the explicit [managed-artifact promotion path](../../docs/02-alm-and-automation.md). GitHub promotion requires a trusted successful export run; local export files are not substitutes for workflow provenance.
6. Publish and validate the target agent separately after import. No live behavior is proven by exporting, passing a checker, or importing a solution.

If you independently unpack an unmanaged export for private source review, preserve the original release bundle. Review tenant data/identifiers before sharing; do not redact IDs inside the release ZIP and still treat it as the original deployable artifact.
