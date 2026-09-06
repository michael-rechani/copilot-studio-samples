# 01: Copilot Studio fundamentals

**Source review: 2026-09-05.** This guide concerns the standard-harness capabilities referenced in the [capability matrix](04-agent-archetypes-and-ai-foundry-harness.md). It is not a statement that every feature is available in every tenant or harness.

## A useful mental model

An agent combines instructions, orchestration, topics, knowledge, and tools. Copilot Studio operates the agent service; Dataverse stores solution components and related configuration. Describing the entire runtime as “hosted inside Dataverse” is misleading.

| Concept | Purpose | Important boundary |
|---|---|---|
| Power Platform environment | Isolates development, testing, or production resources | Not the same as a GitHub environment or Azure resource group |
| Dataverse solution | Packages solution-aware components for ALM | Does not provision Azure resources, copy all external data, or carry every runtime connection |
| Topic | Explicit conversation path with questions, conditions, messages, and tools | Validate required inputs and confirmation before side effects |
| Knowledge | Retrieves source material to inform an answer | Sources differ in authentication, indexing, freshness, citations, and limits |
| Tool | Calls a connector, flow, prompt, or other supported operation | Backend permissions and input validation remain necessary |
| Connected agent | Delegates work to another agent | Has its own identity, permissions, state, runtime, and possibly cost |
| Environment variable / connection reference | Separates deploy-time configuration from reusable components | A reference is not a credential or a newly created target connection |

Knowledge grounding, model invocation, and agent delegation are **three different integration contracts**. Adding Azure AI Search does not call a Foundry agent. Calling a model API does not replace all Copilot Studio models. Connecting an agent does not transfer the signed-in user's permissions to all of its tools.

## Start with knowledge, then add a bounded tool

Use approved, non-sensitive lab content first. Add it on the **Knowledge** page, wait for the source to be ready, and test known-answer and no-answer questions. [Knowledge sources](https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-copilot-studio) support different retrieval and authentication mechanisms. SharePoint/Dataverse user-authenticated retrieval is not equivalent to an uploaded copy of the same document or a search index accessed with a shared identity.

Ask the agent to cite sources and admit missing information. Turning off **Allow ungrounded responses** can block turns that use no knowledge source or tool, but does not guarantee that the model never incorporates general knowledge. Evaluate the actual answer and citation rather than treating a citation as proof of truth.

Use a topic to collect ticket details and show an explicit confirmation summary before a ticket-creation tool. Let deterministic conditions gate that operation; do not rely only on “ask first” in the agent instructions. A backend must also enforce authorization, validate inputs, and prevent duplicate writes.

The [IT support walkthrough](05-it-support-reference-walkthrough.md) gives concrete lab inputs, a proposed tool contract, failure handling, and an evaluation table.

## Identity is configured at more than one layer

1. **User → agent.** Choose **Settings → Security → Authentication**. The options are No authentication, Authenticate with Microsoft, and Authenticate manually. No authentication lets anyone with access to the link interact with the agent. For an internal Teams lab, start with Authenticate with Microsoft and verify sharing restrictions.
2. **Agent → knowledge/tool.** Review the connection and its owner. User authentication and maker/agent-author credentials have different access semantics. Authentication to the conversation does not imply connector SSO or user impersonation.
3. **Tool/agent → downstream system.** That system must validate its own caller identity and authorize access. Do not treat a display name, email supplied in chat, or a prompt variable as proof of identity.
4. **Deployment identity → Dataverse.** A pipeline's application user imports/exports solution components. It is not the end user's runtime identity.

[Authenticate with Microsoft](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configuration-end-user-authentication) exposes `User.ID` and `User.DisplayName`; do not assume `User.Email` or `User.AccessToken` is available. The documented manual-authentication option exposes additional token/login variables. Request only necessary scopes, keep tokens out of prompts/logs, and republish after authentication changes.

Tool authentication is channel-specific: [the documented table](https://learn.microsoft.com/en-us/microsoft-copilot-studio/configure-enduser-authentication) supports user authentication for tools on custom websites and Teams (with required SSO setup), but not Mobile App or Azure Bot Service channels. Slack via Azure Bot Service and mobile delivery are therefore not blanket equivalents of Teams. Check current channel and tenant policies before choosing a deployment surface.

## Solutions and readable source

Build an unmanaged solution in Dev and add the agent plus its solution-aware dependencies. A genuine PAC export creates a ZIP; **export does not automatically unpack it**. A separate unpack operation can produce readable source for review, with the exact layout dependent on tooling and component types. This repository's promotion path intentionally does not unpack or repack.

The editable [IT FAQ](../samples/it-faq-agent/README.md) and [ticket intake](../samples/ticket-intake-agent/README.md) samples provide instructions, single-topic code-editor YAML, and knowledge or connector assets. Their node patterns have official-source provenance, but tenant acceptance and runtime behavior are untested. The old fake solution files were retired. Author in Copilot Studio and use a genuine export; individual topic YAML is not a standalone deployment or whole-agent import.

Power Fx can express conditions and formatting in topic nodes. Variable names, types, scope, and availability must be checked in the authoring canvas. An expression that parses is not evidence that a particular authenticated user property exists at runtime.

## Model and infrastructure boundaries

[Primary model selection](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-select-agent-model) controls generative orchestration and has separate settings from generative responses and prompt builder. Available models depend on region, release status, harness, and administrator settings. This is not an arbitrary fine-tuned endpoint override.

Optional Azure AI Search, model deployments, and Foundry agents are separate resources. The [actual infrastructure inventory](03-infrastructure-as-code.md) explains why creating the provided Azure resources does not create a populated index, permission-filtered retrieval, a Foundry project, or a connected agent.
