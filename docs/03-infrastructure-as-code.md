# 03: Infrastructure as code — actual scope and readiness

**Inspected: 2026-09-05.** These are Azure starter templates, not a complete Copilot Studio or Microsoft Foundry deployment. No provisioning was performed for this documentation. Compilation or `terraform validate` cannot establish that deployment will succeed.

## What the checked-in templates declare

| Resource/capability | `infrastructure\bicep\main.bicep` | `infrastructure\terraform\main.tf` |
|---|---|---|
| Resource group | Uses an existing resource-group deployment scope | Creates `rg-{prefix}-{environment}` |
| Azure OpenAI account | S0; public network access explicitly enabled | S0 account |
| Model deployments | `gpt-4o`, version `2024-05-13`; `text-embedding-3-large`, version `1`; Standard capacity 20 each | **None** |
| Azure AI Search | Standard service, one replica and partition | Standard service |
| Storage | Standard LRS StorageV2 account | Standard LRS storage account |
| Key Vault | Vault with RBAC authorization enabled | **None** |
| Role assignments / managed identities | **None** | **None** |
| Search index, indexer, skillset, vectorizer, semantic configuration, documents | **None** | **None** |
| Foundry project, agent/version, Activity endpoint, runtime hosting | **None** | **None** |
| Copilot Studio agent, connection, environment, channel | **None** | **None** |
| Private networking / complete security baseline | **Not configured** | **Not configured** |

A Search **service is not a vector index**. A vault with RBAC mode enabled does not grant any identity access and contains no secrets until separately populated. The templates do not automatically connect Storage to Search, index files, generate embeddings, or propagate source permissions.

## Known blockers and deployment checks

1. **Storage naming.** Azure storage account names must be globally unique, 3–24 characters, lowercase letters/numbers only. Bicep builds `st` + prefix + environment + a 13-character unique suffix, removing hyphens. With default `copilotstudio` and `dev`, that is **31 characters**, exceeding the maximum. Even a shorter prefix needs validation (for `prod`, at most five prefix characters with the current formula). Terraform's `st{prefix}{environment}` lacks a uniqueness suffix and input validation; a valid-looking default can still collide globally. Do not deploy the Bicep defaults unchanged.
2. **Models and region.** Bicep pins an old `gpt-4o` version (`2024-05-13`). Check current retirement/availability information, deployment type, quota, and subscription access in the actual region. Neither that model nor the embedding deployment is guaranteed deployable. A Copilot Studio model dropdown is unrelated to these Azure deployments.
3. **Resource/API/provider compatibility.** Bicep pins older resource API versions; Terraform pins `azurerm` to `~> 3.90.0` and Terraform `>= 1.5.0`. Review provider behavior and current policy requirements before use. The alternatives are not feature-equivalent.
4. **Security and network design.** Review endpoint exposure, storage access, RBAC, credential ownership, data policy, private network reachability, retention, logging, and resource naming separately. Copilot Studio policy does not configure Azure authorization for you.
5. **Costs and lifecycle.** Obtain approval for Search capacity, model use/capacity, storage, vault, and any separately added runtime or monitoring. Unused provisioned resources can still incur charges.

See [Azure naming rules](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftstorage) and [Azure OpenAI model retirements](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/model-retirements). Resolve blockers in a reviewed infrastructure change before provisioning; this guide does not change the templates.

## Validation before provisioning

Local syntax checks (do not deploy):

```powershell
az bicep build --file infrastructure\bicep\main.bicep
terraform '-chdir=infrastructure\terraform' validate
```

Terraform requires its providers to have been initialized. A successful syntax check is only the first step. An authorized operator must additionally review names, model availability/quota, policy, and a Bicep what-if or Terraform plan against the intended subscription. These tenant/subscription checks have **not been run here**.

The Bicep template targets a **resource group**, not a subscription deployment. Its inputs are `environmentName`, `location`, and `prefix`; the checked-in parameters select `dev`/`eastus`. The separate Azure workflow requires its own reviewed Azure identity/federation and permissions. Power Platform deployment credentials are not Azure provisioning credentials.

`deploy-infrastructure.yml` is manually dispatched with `environment_name` and `azure_region`. Its `prod` target references the GitHub **`production`** environment; the other targets reference `dev` and `test` (Azure `dev` is not the Power Platform export's `development` environment). Configure the applicable environment protections before adding `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` and the corresponding OIDC federation. The job validates inputs before Azure login and passes shell input through environment variables. It does not use the Power Platform `PP_AUTOMATION_ENABLED` gate, fix the template's default naming/model blockers, or prove deployment readiness.

## Connecting resources is a separate implementation

- **Search grounding:** create/populate the index and configure its embedding/vectorizer and semantic ranker as needed; then use a supported Copilot Studio Azure AI Search data connection. Validate citations and retrieval authorization. See [the official Search integration](https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-azure-ai-search).
- **Model invocation:** use a supported model/tool or the documented Azure OpenAI on your data preview path. It is not an automatic model override derived from IaC output.
- **Foundry delegation:** create an appropriate Foundry project/agent separately, enable Activity, review identity and version routing, and add the connection in Copilot Studio. None of those resources are in these templates.

Follow the [capability matrix](04-agent-archetypes-and-ai-foundry-harness.md) for current integration prerequisites and the [IT support reference](05-it-support-reference-walkthrough.md) for an optional lab. Ordinary knowledge Q&A and a ticket flow do not require deploying every Azure resource in this repository.

## Cleanup

Inventory resources and dependencies before deletion. Remove only isolated lab resources that you own, preserve required audit data, remove role assignments/connections/credentials, and verify that billing has stopped. Managed-solution removal does not delete Azure resources, external tickets, or retained logs. Terraform state and Azure resource-group deletion have separate consequences; neither is a universal rollback.
