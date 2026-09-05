# 🤖 Microsoft Copilot Studio Samples & Deployment Automation Guide

Welcome to the **Copilot Studio Samples & Automation** repository! If you are completely new to Microsoft Copilot Studio, this repository provides everything you need to understand, build, version control, and **automate the deployment** of Copilots (Agents), infrastructure, and configurations from Dev to Test to Production.

---

## 📖 Table of Contents
1. [What is Microsoft Copilot Studio? (For Beginners)](#-what-is-microsoft-copilot-studio-for-beginners)
2. [Key Concepts & Mental Model](#-key-concepts--mental-model)
3. [How Copilot Studio Deployment & Automation Works](#-how-copilot-studio-deployment--automation-works)
4. [Repository Structure](#-repository-structure)
5. [Step-by-Step Setup & CI/CD Guide](#-step-by-step-setup--cicd-guide)
   - [Start Here: First-Time Setup Checklist](#start-here-first-time-setup-checklist)
   - [Phase 1: Environment & Authentication (SPN)](#phase-1-environment--authentication-spn)
   - [Phase 2: Exporting from Dev to Source Control](#phase-2-exporting-from-dev-to-source-control)
   - [Phase 3: Automated Deployment via GitHub Actions](#phase-3-automated-deployment-via-github-actions)
   - [Phase 4: Supporting Infrastructure (Azure OpenAI / Search)](#phase-4-supporting-infrastructure-azure-openai--search)
6. [FAQ & Troubleshooting](#-faq--troubleshooting)

---

## 🧠 What is Microsoft Copilot Studio? (For Beginners)

**Microsoft Copilot Studio** (formerly Power Virtual Agents) is Microsoft's low-code SaaS platform for building custom AI assistants ("Agents" / "Copilots"). 

Think of Copilot Studio as combining two powerful capabilities:
1. **Generative AI (Conversational Intelligence):** Point your agent at SharePoint sites, internal documents, public URLs, or Azure OpenAI data, and it immediately answers user questions using retrieval-augmented generation (RAG) with grounded citations.
2. **Deterministic Actions (Logic & Workflows):** When a user asks the agent to perform an action (e.g., *"Create an IT ticket"* or *"Check my order status"*), the agent can execute Power Automate cloud flows, call REST APIs via Custom Connectors, or trigger enterprise plugins.

---

## 🧩 Key Concepts & Mental Model

If you are new to the Power Platform ecosystem, here is how everything fits together:

| Concept | What It Is in Plain English | Analogy |
| :--- | :--- | :--- |
| **Tenant** | Your organization's root Microsoft 365 / Azure domain (`contoso.com`). | The office building. |
| **Power Platform Environment** | An isolated workspace (e.g., `Dev`, `UAT`, `Prod`) containing databases and apps. | Separate floors or rooms in the building. |
| **Dataverse Solution** | A zip container that bundles your Copilot, topics, flows, environment variables, and connectors. | The shipping container for your code. |
| **Copilot / Agent** | The conversational entity with instructions, knowledge sources, and trigger rules. | The employee/assistant. |
| **Topics** | Specific conversational conversation paths (e.g., "Greeting", "Reset Password"). | The script/playbook the agent follows. |
| **Knowledge Sources** | Files, websites, or enterprise search indexes the agent reads to answer questions. | The reference manuals the agent consults. |
| **Actions / Connectors** | API integrations and Power Automate flows that execute external actions. | The tools and systems the agent uses. |
| **Environment Variables** | Configuration values (URLs, client IDs, endpoints) that change between Dev and Prod. | Config files / `.env`. |

---

## 🚀 How Copilot Studio Deployment & Automation Works

In Power Platform, **you do not manually copy-paste bots between environments**. Instead, you use **Application Lifecycle Management (ALM)**:

```
┌─────────────────┐       Export       ┌─────────────────┐       Unpack       ┌─────────────────┐
│   Dev Environ   │ ─────────────────> │ Solution (.zip) │ ─────────────────> │ Git Repository  │
│ (Customization) │   (PAC CLI / SPN)  │   (Unmanaged)   │    (YAML/XML)      │ (.github/...)   │
└─────────────────┘                    └─────────────────┘                    └────────┬────────┘
                                                                                       │
                                                                                 Git Push / PR
                                                                                       │
                                                                                       ▼
┌─────────────────┐       Import       ┌─────────────────┐        Pack        ┌─────────────────┐
│  Prod Environ   │ <───────────────── │ Solution (.zip) │ <───────────────── │  GitHub Actions │
│   (Published)   │   (PAC CLI / SPN)  │    (Managed)    │                    │ (Build Pipeline)│
└─────────────────┘                    └─────────────────┘                    └─────────────────┘
```

1. **Development:** Authors build the Copilot inside an unmanaged Dataverse Solution in the `Dev` environment.
2. **Source Control:** GitHub Actions or `pac` CLI exports the solution and unpacks it into clean, human-readable YAML/XML files in Git.
3. **Continuous Deployment (CI/CD):** When changes merge to `main`, GitHub Actions packs the solution as a **Managed Solution** and deploys it automatically to `Test` and `Production` environments.
4. **Infrastructure as Code (IaC):** Bicep / Terraform scripts provision external Azure AI dependencies (Azure OpenAI, Azure AI Search, Key Vault).

---

## 📁 Repository Structure

```text
copilot-studio-samples/
├── .github/
│   └── workflows/
│       ├── export-dev-agent.yml      # Exports unmanaged solution from Dev -> commits to Git
│       ├── deploy-agent.yml          # Packs solution -> deploys as Managed to Test/Prod
│       └── deploy-infrastructure.yml # Deploys Azure OpenAI, AI Search, Storage, and Key Vault
├── docs/
│   ├── 00-first-time-setup-checklist.md  # Start here if you're brand new
│   ├── 01-copilot-studio-fundamentals.md  # Deep dive into agent structure & Power Fx
│   ├── 02-alm-and-automation.md          # Full ALM guide, solutions, & PAC CLI
│   └── 03-infrastructure-as-code.md      # Azure OpenAI & enterprise search integration
├── config/
│   ├── deployment-settings.test.json # Test environment overrides
│   └── deployment-settings.prod.json # Production environment overrides
├── infrastructure/
│   ├── bicep/
│   │   ├── main.bicep               # Bicep for Azure OpenAI, AI Search, & Key Vault
│   │   └── parameters.json
│   └── terraform/
│       ├── main.tf                  # Terraform alternative for cloud infra
│       └── variables.tf
├── samples/
│   └── faq-support-agent/           # Sample unpacked Copilot Studio solution
│       ├── solution.xml             # Solution manifest & dependencies
│       ├── customizations.xml       # Metadata & configurations
│       └── src/
│           ├── botcomponents/       # Individual topics, dialogs, & settings
│           └── environmentvariabledefinitions/ # Dynamic config values
└── scripts/
    ├── export-agent.ps1             # Local PAC CLI script to export & unpack
    ├── import-agent.ps1             # Local PAC CLI script to pack & import
    └── setup-service-principal.ps1  # Script to create Azure Entra App Registration
```

---

## 🛠️ Step-by-Step Setup & CI/CD Guide

### Start Here: First-Time Setup Checklist
If you are brand new to Copilot Studio, start with:

```text
docs/00-first-time-setup-checklist.md
```

That checklist walks through environments, solutions, authentication, repository secrets, first export, first deployment, and infrastructure deployment.

> Important: The included `samples/faq-support-agent` files are educational placeholders. For a real production deployment, first export a real Dataverse solution from your Dev environment using PAC CLI or the `export-dev-agent.yml` workflow.

### Phase 1: Environment & Authentication (SPN)
To allow GitHub Actions to communicate with Power Platform without human passwords, configure a **Service Principal Name (SPN)**:

1. **Register an App in Microsoft Entra ID:**
   - Azure Portal -> Microsoft Entra ID -> App registrations -> **New registration**.
   - Create a client secret (or certificate) and note the `Client ID`, `Tenant ID`, and `Client Secret`.
2. **Add as Application User in Power Platform:**
   - Go to [Power Platform Admin Center](https://admin.powerplatform.microsoft.com).
   - Select your Environment (`Dev` / `Test` / `Prod`) -> **Settings** -> **Users + permissions** -> **Application users**.
   - Click **+ New app user**, choose your Entra App, and assign the **System Administrator** security role.
3. **Configure GitHub Repository Secrets:**
   Add these secrets in GitHub Settings -> Secrets and variables -> Actions:
   - `PP_ENVIRONMENT_URL_DEV`: `https://your-org-dev.crm.dynamics.com/`
   - `PP_ENVIRONMENT_URL_PROD`: `https://your-org.crm.dynamics.com/`
   - `PP_TENANT_ID`: Azure Tenant ID
   - `PP_CLIENT_ID`: Entra App Client ID
   - `PP_CLIENT_SECRET`: Entra App Client Secret

---

### Phase 2: Exporting from Dev to Source Control
Run the automated export workflow or local script:
```powershell
# Using Power Platform CLI locally:
cd scripts
.\export-agent.ps1 -EnvironmentUrl "https://org-dev.crm.dynamics.com" -SolutionName "FAQSupportAgent"
```
This downloads the solution archive, unpacks the YAML dialogs, and organizes them in `samples/faq-support-agent`.

---

### Phase 3: Automated Deployment via GitHub Actions
When you push code or merge a Pull Request into `main`:
1. The **`deploy-agent.yml`** workflow triggers automatically.
2. It packs the solution into a production-grade **Managed** zip file.
3. It imports the solution into your target environment (`Test`/`Prod`).
4. It publishes the customizations and activates the Copilot.

---

### Phase 4: Supporting Infrastructure (Azure OpenAI / Search)
If your agent connects to private corporate data or custom LLM endpoints:
```bash
# Deploy supporting Azure resources with Azure CLI & Bicep:
az deployment sub create \
  --location eastus \
  --template-file infrastructure/bicep/main.bicep \
  --parameters environment=prod
```

---

## ❓ FAQ & Troubleshooting

- **Why should I deploy solutions as "Managed" in Production?**
  Managed solutions lock customizations in downstream environments, preventing accidental direct edits in production and ensuring clean uninstall/rollback capability.
- **Can I version-control individual Copilot topics?**
  Yes! When unpacked with PAC CLI, each topic and bot component is serialized into individual YAML/JSON files that support standard Git diffs, PR reviews, and merge conflict resolution.
- **What tool is required locally?**
  Install the Power Platform CLI: `dotnet tool install --global Microsoft.PowerPlatform.CLI.Tool` or `winget install Microsoft.PowerPlatformCLI`.
