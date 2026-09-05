# 🧠 04: Agent Archetypes & Copilot Studio as an AI Foundry Harness

This guide breaks down **what types of AI agents you can build** in Microsoft Copilot Studio and explains how Copilot Studio serves as an **enterprise delivery harness for Azure AI Foundry** (formerly Azure AI Studio).

---

## 🏗️ 1. What Can You Build in Copilot Studio? (Agent Archetypes)

Copilot Studio is not limited to simple FAQ chatbots. It supports a spectrum from deterministic conversational bots to autonomous, multi-step enterprise agents:

| Agent Archetype | How It Works | Key Enterprise Use Cases |
| :--- | :--- | :--- |
| **1. Grounded Knowledge Agents (RAG)** | Ingests SharePoint, public websites, Dataverse tables, uploaded PDFs, or Azure AI Search indexes to generate answers with cited sources. | HR policy lookups, IT troubleshooting guides, compliance manuals, technical product manuals. |
| **2. Deterministic Action & Workflow Agents** | Combines conversational intake with structured Power Automate flows or REST API connectors to execute transactional operations. | IT ticket creation (ServiceNow/Jira), ERP balance inquiries (SAP), PTO requests (Workday), password resets. |
| **3. Autonomous & Event-Driven Agents** | Runs autonomously without direct human prompting, triggered by business events (e.g., Dataverse record updates, emails received, webhooks). | Automated invoice triage, lead qualification & assignment, security alert remediation, scheduled status digests. |
| **4. Declarative Agents for Microsoft 365** | Extends Microsoft 365 Copilot directly inside Teams, Outlook, and Word with tailored instructions, company data grounding, and scoped actions. | Project management copilots inside Teams channels, sales pitch assistants embedded in Word. |
| **5. Multi-Agent Orchestrators** | A parent orchestrator agent interprets user intent and delegates sub-tasks to specialized domain agents or external pro-code agents. | Customer service front-desk agent delegating to Billing, Logistics, and Tech Support sub-agents. |

---

## 🤝 2. Copilot Studio as a Harness for Azure AI Foundry

### The Paradigm: Low-Code Delivery + Pro-Code AI Engine

A common enterprise pattern is pairing **Azure AI Foundry** (pro-code model training, fine-tuning, prompt engineering, custom agents) with **Copilot Studio** (governance, distribution, security, and low-code orchestration):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Microsoft Copilot Studio (The Delivery Harness)           │
│                                                                             │
│  Channels: Teams · Web Chat · M365 Copilot · Mobile · Slack                 │
│  Security: Entra ID SSO · Tenant DLP · Role-Based Access Control             │
│  Orchestration: Visual Dialog Trees · Topic Routing · Human Escalation      │
│  Governance: Power Platform ALM · Environment Separation · Maker Controls   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                      Direct Integrations / Connectors
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│                      Azure AI Foundry (The Pro-Code Engine)                  │
│                                                                             │
│  Models: Fine-tuned GPT-4o · Phi-3 · Open-source OSS Models (Llama/Mistral) │
│  Code Agents: Semantic Kernel (C#/Python) · LangChain · Azure AI Agents     │
│  Data & RAG: Azure AI Search Vector Pipelines · Document Intelligence       │
│  Ops: LLM Evaluation Suites · Red Teaming · Content Safety Filters          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔌 3. How to Connect Copilot Studio to Azure AI Foundry

There are three primary architectural integration patterns:

### Pattern A: Direct Knowledge Source via Azure AI Search (Zero-Code RAG)
1. In **Azure AI Foundry**, build a custom search index over your data lake using **Azure AI Search** with vector embeddings and hybrid semantic search.
2. In **Copilot Studio**, navigate to **Knowledge** -> **+ Add knowledge** -> **Azure AI Search**.
3. Supply the search endpoint, index name, and semantic configuration. The agent automatically handles query vectorization and citations.

### Pattern B: Azure OpenAI on Your Data (Model Grounding)
1. Deploy a custom model (e.g., fine-tuned `gpt-4o`) in Azure AI Foundry / Azure OpenAI.
2. Connect your Copilot Studio agent's Generative Answers node directly to the Azure OpenAI endpoint with system prompt and temperature overrides.

### Pattern C: Custom REST Connectors to Azure AI Agent Service / Python APIs
For complex code-first multi-agent systems built with Semantic Kernel, LangGraph, or Azure Functions:
1. Wrap your Azure AI Foundry Python/C# agent behind an Azure App Service or API Management (APIM) endpoint with an OpenAPI (Swagger) definition.
2. In Power Platform, create a **Custom Connector** pointing to that OpenAPI definition.
3. In Copilot Studio, add an **Action** node that invokes the connector, passing conversation history and parameters to your pro-code agent and rendering the response back to the user in Teams or Web Chat.

---

## ⚖️ When to Choose Which Platform

| Requirement | Build in Copilot Studio | Build in Azure AI Foundry |
| :--- | :---: | :---: |
| Rapid deployment to Teams / Outlook / Web | ✅ | ❌ (requires custom UI) |
| Non-technical authors editing dialog flows | ✅ | ❌ |
| Custom Python / LangChain / Semantic Kernel logic | ❌ | ✅ |
| Fine-tuning custom open-weights models | ❌ | ✅ |
| Automated prompt evaluation & red-teaming metrics | ❌ | ✅ |
| Turnkey enterprise Entra ID authentication & DLP | ✅ | ❌ (requires custom code) |
