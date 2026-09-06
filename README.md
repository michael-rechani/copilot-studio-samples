# Microsoft Copilot Studio samples and deployment guidance

Community teaching material for building an agent in Copilot Studio and promoting a **real exported Dataverse solution** from Dev to Test and Production. This is not an official Microsoft repository or a production-ready deployment.

**Documentation checked against official sources: 2026-09-05.** Product availability depends on harness, region, licensing, tenant policies, authentication, and channel. No tenant import, live agent, Foundry connection, or Azure deployment has been validated by this documentation work. Local/static validation is not evidence of deployment readiness.

## Start here

1. [First-time setup checklist](docs/00-first-time-setup-checklist.md): environment protection before credentials.
2. [Fundamentals](docs/01-copilot-studio-fundamentals.md): knowledge, topics, tools, and identity.
3. [ALM and automation](docs/02-alm-and-automation.md): export provenance, validation, manual promotion, and separate publication.
4. [Infrastructure scope and limitations](docs/03-infrastructure-as-code.md): what the templates actually create.
5. [Capability matrix and Foundry integration](docs/04-agent-archetypes-and-ai-foundry-harness.md): sourced distinctions between search, model calls, and delegation.
6. [Beginner IT support walkthrough](docs/05-it-support-reference-walkthrough.md): knowledge Q&A, a user-confirmed ticket tool, and an optional Foundry specialist.

## Editable starter agents

| Sample | What you can use now |
|---|---|
| [IT FAQ agent](samples/it-faq-agent/README.md) | Paste agent instructions, upload five fictional approved FAQs, and paste a scope topic; includes grounding/citation setup and expected answers |
| [Ticket intake agent](samples/ticket-intake-agent/README.md) | Paste a topic that collects summary/category, previews, and explicitly confirms or cancels a **draft only**; includes an optional, unwired OpenAPI 2.0 lab contract |

Each sample maps actual files to Copilot Studio UI surfaces and includes manual
test cases. Topic syntax is based on [pinned Microsoft sources](samples/SOURCES.md);
**tenant save/import and runtime behavior remain untested**. These are editable
single-topic/config assets, not whole-agent or Dataverse solution imports. No
backend or credentials are provided. Genuine exports are still required for
promotion. The old fake solution/topic files have been [retired](samples/faq-support-agent/README.md).

## What can you build?

- **Knowledge Q&A:** retrieve approved material and generate answers with source references. Retrieval and citations do not guarantee correctness or permission filtering for every source.
- **Task-oriented agents:** collect and validate inputs, request confirmation, then call a configured connector or flow. A prompt is not an authorization boundary.
- **Event-driven agents:** respond to configured triggers, subject to trigger identity, policy, limits, and approvals.
- **Specialist delegation:** connect supported agents or integrate an external API. This is different from retrieving a document or invoking a model.

Copilot Studio can provide conversational orchestration and supported channels around Microsoft Foundry capabilities. It does **not** automatically host every framework, propagate user permissions to every API, or replace its generative-answer model with any fine-tuned endpoint.

The direct **Copilot Studio → Microsoft Foundry agent connection is preview, for the standard harness**. It requires an agent created in the **new Foundry portal** with the **Activity protocol enabled programmatically through REST or Python SDK**. Responses/A2A defaults alone are insufficient (runtime 400); previous-portal agents can return `404 - Version not found`. Configure it under **Agents → Add an agent → Microsoft Foundry**, using a Foundry **project endpoint** connection and the **Agent Id**. See the [official connection guide](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-foundry-agent) and [detailed prerequisites](docs/04-agent-archetypes-and-ai-foundry-harness.md).

## Deployment model: explicit promotion, not push-to-deploy

```text
Dev unmanaged solution (built in the tenant)
  -> manually dispatch main-branch export
  -> solution-export Actions artifact
       solution.zip (genuine managed export)
       source_unmanaged.zip (unmanaged export)
       settings-template.json + manifest.json (names, version, hashes, provenance)
  -> separately review target deployment settings
  -> manually dispatch promotion to TEST (default)
  -> origin/archive/settings validation + blocking solution checker + import
  -> validate and separately publish/test the target agent
  -> manually dispatch the same export to PROD through configured GitHub approvals
```

There is **no deployment on push**, no export commit/push, and no unpack/repack in this promotion path. The unmanaged archive is retained for review/recovery; it is not converted into the managed payload. Solution import and `pac solution publish` are not agent publication.

### Configure GitHub before adding credentials

Create GitHub environments **`development`**, **`test`**, and **`production`**. Configure production **required reviewers and deployment branch restrictions** in GitHub Settings → Environments; YAML naming an environment does not enforce those protections by itself. Restrict deployment to `main`, protect changes to workflows/settings, and review environment access.

Each environment needs its own values for the same four **environment secrets**:

| Secret | Meaning |
|---|---|
| `PP_ENVIRONMENT_URL` | This environment's Dataverse HTTPS URL |
| `PP_TENANT_ID` | Its Entra tenant ID |
| `PP_CLIENT_ID` | Its approved deployment application ID |
| `PP_CLIENT_SECRET` | That application's secret |

**Do not define these names at repository or organization scope as fallbacks.** GitHub secret resolution can fall back to broader scopes; YAML cannot prove the origin of a resolved secret. Administrators must verify this configuration. Use separate least-privilege application users for each environment. Only after protections and identities are reviewed, add environment credentials and set that environment's `PP_AUTOMATION_ENABLED` variable to `true`.

Run `export-dev-agent.yml` from `main` against a real Dev solution. Run `deploy-agent.yml` from `main` with `export_run_id`, the expected unique `solution_name`, and `target_environment` (`TEST` by default, `PROD` explicitly). The export must be a successful run of this repository's approved main-branch export workflow. The included [deployment settings](config/README.md) deliberately contain blocked placeholders.

## Repository map

| Path | Purpose |
|---|---|
| `.github/workflows/export-dev-agent.yml` | Manual Dev export into one Actions artifact |
| `.github/workflows/deploy-agent.yml` | Manual, validated managed-artifact promotion |
| `.github/workflows/validate.yml` | Local/static repository checks; not tenant certification |
| `.github/workflows/deploy-infrastructure.yml` | Separate Azure provisioning workflow; review template limitations first |
| `scripts/export-agent.ps1` | Export managed/unmanaged archives and manifest into a fresh `out\export` by default |
| `scripts/validate-deployment.ps1` | Offline archive/manifest/settings validation |
| `scripts/import-agent.ps1` | Explicit local import; **bypasses GitHub approvals** |
| `config/` | Separately reviewed environment settings, never credentials |
| `infrastructure/` | Unequal Bicep and Terraform starter templates, not a complete Foundry/RAG deployment |
| `samples/it-faq-agent/` | Instructions, fictional Markdown knowledge, scope topic, and manual cases |
| `samples/ticket-intake-agent/` | Confirm/cancel draft topic, instructions, unwired lab API contract, and manual cases |
| `samples/SOURCES.md` | Official schema/setup references and adapted-pattern license notice |

For local commands, checker behavior, artifact retention, release evidence, rollback considerations, and publication, follow the [ALM guide](docs/02-alm-and-automation.md), not a sample-folder packaging shortcut.

[Contributing](CONTRIBUTING.md) · [License](LICENSE)
