# First-Time Setup Checklist

Use this checklist if you know nothing about Copilot Studio or Power Platform ALM. Work through it in order.

## 1. Create three Power Platform environments

Create separate environments in the Power Platform Admin Center:

| Environment | Purpose | Solution type |
|---|---|---|
| Dev | Build and edit the Copilot Studio agent | Unmanaged |
| Test | Validate deployment before production | Managed |
| Prod | Serve real users | Managed |

Do not directly edit agents in Test or Prod. Treat Dev and Git as the source of truth.

## 2. Create a Dataverse solution in Dev

In the Dev environment:

1. Open Power Apps or Copilot Studio.
2. Create a new solution, for example `FAQSupportAgent`.
3. Create or add your Copilot Studio agent to that solution.
4. Add related assets to the same solution:
   - Agent topics
   - Power Automate flows
   - Connection references
   - Environment variables
   - Custom connectors

## 3. Install local tools

Install the Power Platform CLI:

```powershell
dotnet tool install --global Microsoft.PowerPlatform.CLI.Tool
```

Or install it with winget:

```powershell
winget install Microsoft.PowerPlatformCLI
```

Verify installation:

```powershell
pac --version
```

## 4. Create deployment identity

Run this repository's helper script:

```powershell
cd scripts
.\setup-service-principal.ps1 -AppName "GitHub-CopilotStudio-Deployer"
```

Then add the generated application as an Application User in every Power Platform environment.

## 5. Add GitHub Actions secrets

Add these in GitHub repository settings under **Secrets and variables** -> **Actions**.

| Secret | Example |
|---|---|
| `PP_TENANT_ID` | `00000000-0000-0000-0000-000000000000` |
| `PP_CLIENT_ID` | `11111111-1111-1111-1111-111111111111` |
| `PP_CLIENT_SECRET` | `your-client-secret` |
| `PP_ENVIRONMENT_URL_DEV` | `https://contoso-dev.crm.dynamics.com` |
| `PP_ENVIRONMENT_URL_TEST` | `https://contoso-test.crm.dynamics.com` |
| `PP_ENVIRONMENT_URL_PROD` | `https://contoso.crm.dynamics.com` |
| `AZURE_CLIENT_ID` | Azure deployment app registration client ID |
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

For Azure infrastructure deployment, configure OpenID Connect federated credentials for the GitHub repository instead of storing Azure client secrets.

## 6. Export the real Dev solution into Git

The included sample files are educational placeholders. Replace them with a real exported Copilot Studio solution before using production deployment.

Run:

```powershell
cd scripts
.\export-agent.ps1 `
  -EnvironmentUrl "https://contoso-dev.crm.dynamics.com" `
  -SolutionName "FAQSupportAgent" `
  -OutputFolder "../samples/faq-support-agent"
```

Commit the exported files and open a pull request.

## 7. Deploy to Test and Prod

Use the `Deploy Copilot Studio Solution` workflow:

1. Run it manually for `TEST`.
2. Validate the agent in Copilot Studio.
3. Run it manually for `PROD` after approval.

## 8. Deploy supporting Azure infrastructure

Use the `Deploy Azure Infrastructure for Copilot Studio` workflow or run Bicep locally:

```powershell
az group create --name rg-copilotstudio-dev --location eastus
az deployment group create `
  --resource-group rg-copilotstudio-dev `
  --template-file infrastructure/bicep/main.bicep `
  --parameters infrastructure/bicep/parameters.json
```

