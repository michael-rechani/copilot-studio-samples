# 🔄 02: Application Lifecycle Management (ALM) & Automation

This guide covers everything you need to know about setting up robust CI/CD pipelines for Microsoft Copilot Studio.

---

## 🏛️ Environments Strategy (Dev -> Test -> Prod)

To prevent breaking changes in production, maintain at least 3 isolated Power Platform environments:

```
[ Developer Environment ] (Unmanaged Solution)
          │
          │ 1. pac solution export & unpack
          ▼
[ Git Repository ] (YAML & XML Source Control)
          │
          │ 2. pac solution pack (Managed)
          ▼
[ Build / Test Environment ] (Managed Solution - Automated Integration Tests)
          │
          │ 3. Automated Approval & Promotion
          ▼
[ Production Environment ] (Managed Solution - Live End Users)
```

---

## 📦 Unmanaged vs. Managed Solutions

| Attribute | Unmanaged Solution | Managed Solution |
| :--- | :--- | :--- |
| **Where to use** | **Development environments ONLY.** | **Test, Staging, and Production.** |
| **Direct Edits** | Allowed directly in the UI. | Locked down (prevents accidental configuration drift). |
| **Source of Truth** | Developer sandbox. | Git Repository artifact. |
| **Uninstall Behavior** | Deleting the solution leaves components behind. | Deleting removes all components cleanly. |

---

## 🔑 Setting Up Service Principal Authentication (SPN)

Automated pipelines (like GitHub Actions or Azure DevOps) require an Entra ID Application Registration instead of human user accounts.

### Step 1: Register App in Microsoft Entra ID
1. Navigate to **Azure Portal** -> **Microsoft Entra ID** -> **App registrations**.
2. Click **New registration**. Name: `GitHub-CopilotStudio-Deployer`.
3. Go to **Certificates & secrets** -> **New client secret**. Save the value securely.
4. Under **API permissions**, add:
   - Dynamics CRM -> Delegated -> `user_impersonation`

### Step 2: Create Application User in Power Platform Admin Center
1. Open [Power Platform Admin Center](https://admin.powerplatform.microsoft.com).
2. For EACH environment (`Dev`, `Test`, `Prod`):
   - Go to **Environments** -> [Your Environment] -> **Settings**.
   - Under **Users + permissions**, select **Application users**.
   - Click **+ New app user**.
   - Select your registered Azure App (`GitHub-CopilotStudio-Deployer`).
   - Assign the **System Administrator** security role (or a custom role with Solution Import/Export privileges).

---

## 🧰 Power Platform CLI (`pac`) Essential Commands

The `pac` tool is Microsoft's official cross-platform CLI for Power Platform ALM:

```powershell
# 1. Authenticate with an environment using SPN:
pac auth create `
  --url "https://contoso-dev.crm.dynamics.com" `
  --tenant "00000000-0000-0000-0000-000000000000" `
  --applicationId "11111111-1111-1111-1111-111111111111" `
  --clientSecret "YourSecretHere"

# 2. Export unmanaged solution from Dev:
pac solution export `
  --name "FAQSupportAgent" `
  --path "./out/FAQSupportAgent.zip" `
  --managed false

# 3. Unpack solution into source control directory:
pac solution unpack `
  --zipFile "./out/FAQSupportAgent.zip" `
  --folder "./samples/faq-support-agent" `
  --packagetype Both

# 4. Pack source control folder into a Managed zip:
pac solution pack `
  --zipFile "./out/FAQSupportAgent_managed.zip" `
  --folder "./samples/faq-support-agent" `
  --packagetype Managed

# 5. Import managed solution to Production:
pac solution import `
  --path "./out/FAQSupportAgent_managed.zip" `
  --force-overwrite `
  --publish-changes

# 6. Publish all customizations in the environment:
pac solution publish
```

---

## 🌐 Handling Environment Variables & Connection References

In production, your Copilot will likely connect to different endpoints (e.g., Dev API vs. Prod API).

Use **Dataverse Environment Variables**:
- In Dev: Define variable `cr123_ApiEndpoint` with default value `https://dev-api.contoso.com`.
- In Deployment Pipeline: Provide a `deploymentSettings.json` file to override the value in Production:

```json
{
  "EnvironmentVariables": [
    {
      "SchemaName": "cr123_ApiEndpoint",
      "Value": "https://api.contoso.com"
    }
  ],
  "ConnectionReferences": [
    {
      "LogicalName": "cr123_sharedsharepointonline_12345",
      "ConnectionId": "00000000-0000-0000-0000-000000000000",
      "ConnectorId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline"
    }
  ]
}
```
