# 00: First-time setup checklist

**Reviewed 2026-09-05.** Start with a lab, not Production. The sample files and [IT support walkthrough](05-it-support-reference-walkthrough.md) are illustrative and not importable or tenant-tested. No tenant calls are needed to read this guide or run offline validation.

## 1. Decide what you are building

- [ ] Read [fundamentals](01-copilot-studio-fundamentals.md) and the [dated capability matrix](04-agent-archetypes-and-ai-foundry-harness.md).
- [ ] Choose a supported harness/channel, identify runtime users and connection owners, and obtain licensing/capacity and data-policy approval.
- [ ] Begin with knowledge Q&A and a user-confirmed ticket topic. Treat Foundry delegation as optional **preview** and do not provision Azure resources unnecessarily.

## 2. Create separate Power Platform environments and a real solution

| Environment | Purpose | Solution |
|---|---|---|
| Dev | Author and test changes | Unmanaged |
| Test | Validate the actual release artifact | Managed export from Dev |
| Prod | Serve approved users | Same managed export evaluated in Test |

- [ ] Create environments with the required Dataverse/Copilot Studio access.
- [ ] In Dev, create a solution (for example, unique name `FAQSupportAgent`), then add the agent and solution-aware dependencies: topics, flows, connection references, environment variables, and custom connectors as applicable.
- [ ] Confirm that target connections, owners, downstream permissions, and external resources will be provisioned separately.
- [ ] Do not assume managed solutions prevent all downstream edits or guarantee clean rollback; see [ALM considerations](02-alm-and-automation.md).

## 3. Protect GitHub environments — before credentials

GitHub environments are separate from Power Platform environments.

- [ ] Create **`development`**, **`test`**, and **`production`** under GitHub Settings → Environments.
- [ ] Restrict allowed deployment branches to **`main`**. Protect `main` and require review of workflows, scripts, and target settings.
- [ ] Configure **required reviewers** for `production`, review self-approval/admin bypass policy, and verify these features are supported by your repository visibility/GitHub plan.
- [ ] Verify a production job actually waits for approval. YAML's `environment: production` only references the environment; it does **not** create reviewer or branch protection rules.
- [ ] Ensure none of the four `PP_*` secret names below exists at repository or inherited organization scope as a fallback. YAML cannot determine the storage scope of a resolved secret.
- [ ] Keep `PP_AUTOMATION_ENABLED` unset/false and **do not add deployment credentials until the protections and identity review are complete**. If required protections are unavailable, do not enable production deployment.

## 4. Create and scope deployment identities

- [ ] Create an approved Entra application/service principal and Dataverse application user for each environment, using separate identities where practical to keep Dev/Test unable to import into Prod.
- [ ] Assign narrowly scoped roles sufficient for export, solution checker, or import as appropriate. Do not grant System Administrator by default.
- [ ] Have an administrator review any use of `scripts\setup-service-principal.ps1`; it creates identity resources, not complete environment authorization/protection.
- [ ] Do not confuse client-credential application-user access with a human's delegated `user_impersonation` permission or runtime user authentication.
- [ ] Record credential owner, rotation, expiry, and incident revocation procedure privately.

## 5. Configure environment secrets and explicit enablement

Only after step 3/4 approval, define these **same four environment-secret names separately in each environment**:

| GitHub environment | `PP_ENVIRONMENT_URL` | Other secrets |
|---|---|---|
| `development` | Dev Dataverse HTTPS origin URL | Its own `PP_TENANT_ID`, `PP_CLIENT_ID`, `PP_CLIENT_SECRET` |
| `test` | Test Dataverse HTTPS origin URL | Its own `PP_TENANT_ID`, `PP_CLIENT_ID`, `PP_CLIENT_SECRET` |
| `production` | Prod Dataverse HTTPS origin URL | Its own `PP_TENANT_ID`, `PP_CLIENT_ID`, `PP_CLIENT_SECRET` |

- [ ] No repository/organization-level fallback for these names; no old `PP_ENVIRONMENT_URL_DEV/TEST/PROD` convention.
- [ ] Set **that environment's** `PP_AUTOMATION_ENABLED` variable to the exact value `true` only when ready.
- [ ] Understand that this enablement flag is an operator acknowledgment, not automatic verification of GitHub settings or identity permissions.
- [ ] Keep Azure infrastructure identity/federation settings separate. Power Platform credentials do not authorize Azure provisioning.

## 6. Export genuine managed and unmanaged archives

- [ ] Freeze Dev edits for the export window; managed/unmanaged exports are sequential, not an atomic snapshot.
- [ ] Manually run **Export Copilot Solution from Dev** (`export-dev-agent.yml`) on **`main`**, entering the real unique solution name.
- [ ] Record the successful Actions **run ID**. Download/inspect its **`solution-export`** artifact containing `solution.zip` (managed), `source_unmanaged.zip`, `settings-template.json`, and `manifest.json`.
- [ ] Review solution name/version, managed flags, hashes, and run provenance. Preserve the bundle together. Do not unpack/repack or commit/push an export as part of this workflow.
- [ ] Review artifact access and retention; these archives may contain sensitive tenant configuration. The workflow's retention is finite (currently 30 days).

For local export, install a supported PAC CLI and follow the explicit command in [the ALM guide](02-alm-and-automation.md). The default output is a **fresh `out\export`**, not the sample folder.

## 7. Review target settings against this export

- [ ] Use the exported `settings-template.json` generated by `pac solution create-settings`.
- [ ] Populate separately reviewed `config\deployment-settings.test.json` and `config\deployment-settings.prod.json` with actual target values and existing connection IDs. Keep schema/reference keys exactly aligned with the export.
- [ ] The included placeholders intentionally fail validation. Do not merely remove the word `REPLACE_`; generate settings from the real export.
- [ ] Verify connection owners, sharing, connector IDs, permissions, URLs, data residency, and authentication in the target; no credentials in settings/Git.
- [ ] Run offline archive/settings validation as documented in [config guidance](../config/README.md).

## 8. Explicitly promote to Test

- [ ] Manually run **Promote Copilot Solution** (`deploy-agent.yml`) on **`main`** with `target_environment: TEST` (the default), the successful `export_run_id`, and expected `solution_name`.
- [ ] Require trusted same-repository export origin, archive/manifest/settings validation, and blocking solution checker to succeed. Never bypass a failed or missing checker report.
- [ ] Verify import results and dependencies in Test. Import does not automatically publish the agent or activate flows.
- [ ] Review and separately publish the intended target bot, then validate a **new live-channel session**, sign-in, knowledge, tools, cancellation, isolation, and failure paths. Record [evaluation results](05-it-support-reference-walkthrough.md#7-repeatable-evaluation-before-release).

## 9. Promote to Prod only after evidence and approval

- [ ] Have reviewers inspect Test evidence, the same export run/hash/version, Prod settings, target identity, rollback/recovery plan, and costs.
- [ ] Manually dispatch with `target_environment: PROD` and the **same export run**. Approve only through the configured `production` environment gate.
- [ ] Verify import, separately authorize agent publication/flow activation as required, and repeat live-channel smoke/access tests.
- [ ] Remember: a direct local import **bypasses GitHub environment approvals**. Do not use it as an approval workaround.

## 10. Optional Azure resources and cleanup

- [ ] Read [actual template limitations](03-infrastructure-as-code.md) before provisioning: Bicep default storage naming exceeds the limit; pinned model availability is not guaranteed; Terraform omits model deployments/Key Vault; neither creates Foundry agents or search indexes.
- [ ] Obtain separate Azure permissions, plan/what-if review, budget, and cleanup approval.
- [ ] Remove only owned lab resources, grants, connections, test tickets, and credentials; apply approved log/artifact retention. Verify billing and access after cleanup.
