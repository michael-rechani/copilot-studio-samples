# 04: Agent patterns and Microsoft Foundry integration

**Capability/source review date: 2026-09-05.** Sources below are official Microsoft documentation retrieved on that date. “Documented” means described by the source, not verified in this repository's tenant. Availability, preview status, region, licensing, harness, policy, and channel must be rechecked before implementation. All runtime examples here are **not tenant-tested**.

“Delivery harness” below is an architectural description of Copilot Studio providing conversation and channels. It is not a promise of universal framework hosting or security inheritance. The direct Foundry connection documentation specifically applies to Copilot Studio's **standard harness**, not every harness offered by the product.

## Capability matrix

| Pattern | Documented capability as of 2026-09-05 | Prerequisites / limits | What it does not mean |
|---|---|---|---|
| Knowledge Q&A | Supported knowledge sources ground answers [1] | Source-specific authentication, limits, freshness, and citations; evaluate correctness | Uploaded documents and all external indexes automatically preserve original per-user ACLs |
| Azure AI Search grounding | Add Search through a formal data connection; supports configured integrated vectorization and semantic ranker [2] | Prepare the index/vectorizer and semantic settings first; one vector index per documented connection flow; citation URL required | Copilot Studio creates a populated index or universally handles embeddings/permission filtering |
| Primary model selection | Select an offered orchestration model [3] | Model availability/release status varies; orchestration, generative-response, and prompt settings are separate | Arbitrary fine-tuned model endpoint replaces all generative answers |
| Azure OpenAI on your data | **Preview**, standard-harness generative-answers integration [4] | Documented Azure data/model setup and connection; **Classic data** configuration in the topic node | Any model API/fine-tune can be pasted into a normal knowledge-source dialog with universal system-prompt/temperature overrides |
| Connector/API tool | Supported prebuilt/custom connectors invoke operations [5] | Supported connection auth, schema, network access, DLP, authorization, and service limits | Tool calls automatically act as the conversational user |
| Foundry agent delegation | **Preview**, direct external-agent connection for the standard harness [6] | **New Foundry portal** agent, enabled **Activity** protocol, project endpoint, Agent Id, valid connection | Responses/A2A defaults suffice, or previous-portal agents work unchanged |
| Framework-based specialist | Foundry hosted agents can run packaged custom/framework code [7] | Deliberate container deployment, compatible protocols, runtime dependencies, identity, and lifecycle setup | Every Semantic Kernel/LangGraph application already runs in Foundry or becomes connectable just by using its models |
| Channels | Publish to supported/configured channels [8] | Each channel has separate setup, authentication, and experience limits; administrators can restrict availability | Slack/mobile/custom apps have identical SSO, tool authentication, UI, or delivery behavior |
| User authentication | Agent sign-in and tool authentication are separately configured [9][10] | Tool user-auth table excludes Azure Bot Service channels and Mobile App; Teams requires documented SSO setup | Entra sign-in, DLP, or an incoming user ID automatically propagates authorization through all downstream services |

### Common archetypes

Start with the smallest sufficient design:

- **Knowledge assistant:** answer an approved FAQ with citations and a no-answer path.
- **Transactional assistant:** collect fields, validate, request explicit confirmation, then invoke a narrowly authorized tool.
- **Event-driven assistant:** act on an allowed trigger with a documented trigger/connection identity, bounded workload, and approval rules. No interactive user is necessarily present.
- **Specialist orchestrator:** delegate only tasks requiring distinct capabilities. Additional agents introduce latency, state, identity, data-sharing, and evaluation responsibilities.

Publishing a custom agent to Microsoft 365 Copilot is not the same design contract as a Microsoft 365 declarative agent. Do not infer availability in every Microsoft 365 host application from “Teams + Microsoft 365” channel support.

## Pattern A: Search grounding, not agent delegation

1. In Azure AI Search, prepare the document content, index, embedding model/vectorizer, and any semantic ranker configuration.
2. In Copilot Studio, choose **Add knowledge → Featured → Azure AI Search → Create new connection**. Use the product's formal data connection rather than inventing an endpoint/key field in agent configuration.
3. Choose a supported authentication type and a narrowly authorized connection identity; select the prepared vector index.
4. Wait for **Ready**, then test known/no-answer questions and verify actual citations. Include a source URL field in the index (`metadata_storage_path` is recognized); users still need access to the citation destination.

**Authentication caveat in the source:** the current Search article describes access-key and Entra options, but also warns against manually configuring endpoint/API keys and recommends the formal data-source path with Entra for connection recovery. Follow the current supported connection UI and prefer an approved Entra option where available; do not treat that inconsistent wording as a blanket recommendation to distribute admin keys.

Integrated vectorization works only with the prerequisite Search configuration and compatible embedding model. A Search connection is not proof of document-level authorization: validate which identity queries the index and whether the selected integration enforces per-user filtering. If you cannot prove isolation, restrict the index to content every agent user may see or choose a supported permission-aware source. Do not expose sensitive content merely because citation links themselves require sign-in.

## Pattern B: Model invocation, not a universal override

Use the model-selection controls documented for the particular Copilot Studio feature, or invoke an explicit model/API tool with a defined request/response contract.

The **Azure OpenAI on your data preview** is a specific grounding integration. Its documentation describes connecting data to models in Azure OpenAI, creating a Copilot Studio agent via **Deploy to → A new Microsoft Copilot Studio bot**, then configuring the topic's generative answers node under **Data source → Classic data → Add connection / Connection properties**. That is not a general “paste a fine-tuned endpoint into any generative answers node” capability.

For a custom/fine-tuned model, first verify its supported API/deployment, then deliberately implement and evaluate a tool or specialist that calls it. Review input minimization, output validation, model lifecycle, safety, separate billing, and data residency. Neither the tool nor a Foundry connection silently changes all Copilot Studio model behavior.

## Pattern C: Direct Foundry agent connection (preview)

Use [the official Copilot Studio guide][6] rather than building a custom connector solely because older guidance omitted this native option.

### Prepare the specialist

1. Create the specialist in the **new Microsoft Foundry portal**, in the intended project. Agents created in the previous portal are not supported by this connection and can return **`404 - Version not found`**.
2. Enable the **Activity protocol endpoint**. The Copilot Studio guide states that new agents expose **Responses and A2A** by default; those defaults are **insufficient** for this connection.
3. Follow [Configure and share your agent][11] using **REST API or Python SDK** to update the endpoint protocol configuration. There is **no portal option** to enable Activity in the Copilot Studio prerequisite flow. Do not change authorization schemes blindly: preserve required protocols/schemes and review the actual caller identity and least-privilege roles.
4. Inspect the agent's returned endpoint configuration to verify Activity is enabled. The portal may continue to show only Responses/A2A after a successful update; that omission is expected.
5. Review the stable endpoint's active version. Foundry defaults to routing to the latest version; pin an evaluated version when controlled releases are needed. A new version can otherwise change the specialist without a Copilot Studio solution promotion.

### Connect from Copilot Studio

1. Open the main agent's **Agents** page and select **Add an agent**.
2. Under **Connect to an external agent**, select **Microsoft Foundry**.
3. Select or create the connection using the **Foundry project endpoint URL** (not a model endpoint and not merely an A2A URL).
4. Select **Next**, enter a clear **Name** and routing **Description**, and enter the specialist's **Agent Id**.
5. Select **Add Agent**. Test invocation, identity, data boundaries, errors, and delegation limits before broadening access.

| Symptom | Check / safe response |
|---|---|
| HTTP 400, “endpoint does not support activity” | Enable Activity via REST/Python; Responses/A2A alone do not satisfy the connection |
| `404 - Version not found` | Confirm the agent originated in the new portal and that project/Agent Id match |
| 401/403 | Verify the connection's actual identity, token audience/expiry, endpoint authorization, and least-privilege access; do not “fix” by granting everyone access |
| Timeout/unavailable specialist | Return a bounded unavailable response with correlation ID; offer normal support or an independently confirmed ticket |
| Unexpected answer after a change | Check active Foundry version as well as Copilot Studio published version |

This preview is not recommended for production workloads by the source. Validate independently before relying on it and keep a non-specialist fallback. Copilot Studio/Foundry owners remain responsible for data sharing, permission boundaries, observability, quality, and human oversight.

## Pattern D: An external API when you need a custom contract

An API hosted in Azure Functions, App Service, another approved host, or a deliberately configured Foundry hosted agent can expose a specialist capability. Use an approved connector/OpenAPI definition where that path is supported. Calling Foundry models from an application does not mean Foundry hosts that application.

Define the identity, input/output schema, session mapping, time budget, retry policy, idempotency, error codes, and correlation fields. Never pass raw access tokens or unlimited chat history in a prompt. Connection-owner credentials can grant broader access than the user has; enforce authorization in the backend or use supported user-delegated authentication.

## Sources

All retrieved **2026-09-05**; source pages can change after this review.

1. [Knowledge sources][1]
2. [Add Azure AI Search as a knowledge source][2]
3. [Select a primary AI model][3]
4. [Azure OpenAI for generative answers (preview)][4]
5. [Use connectors in agents][5]
6. [Connect to a Microsoft Foundry agent (preview)][6]
7. [Hosted agents in Foundry Agent Service][7]
8. [Publish and deploy your agent / channels][8]
9. [Configure user authentication][9]
10. [Configure user authentication for tools][10]
11. [Configure and share your Foundry agent][11]

[1]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-copilot-studio
[2]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-azure-ai-search
[3]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-select-agent-model
[4]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/nlu-generative-answers-azure-openai
[5]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/advanced-connectors
[6]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-foundry-agent
[7]: https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/hosted-agents
[8]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-fundamentals-publish-channels
[9]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/configuration-end-user-authentication
[10]: https://learn.microsoft.com/en-us/microsoft-copilot-studio/configure-enduser-authentication
[11]: https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/configure-agent
