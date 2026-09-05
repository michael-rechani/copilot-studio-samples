# 📚 01: Copilot Studio Fundamentals & Architecture

This guide explains the inner workings of Microsoft Copilot Studio for engineers, developers, and architects coming from traditional software development.

---

## 🏗️ What is a Copilot Studio Agent?

In Copilot Studio, an **Agent** (or Copilot) is a composite cloud application hosted within Microsoft Dataverse. It is not just a single prompt or model; it is an orchestration engine that blends:

1. **Conversational Orchestration Engine:** Decides whether to route user queries to a custom deterministic topic or a generative AI knowledge search.
2. **Topics & Dialogs:** Flowchart-like conversation trees built with trigger phrases, conditions, question nodes, and message responses.
3. **Generative AI Grounding (RAG):** Natural language answering grounded over corporate data sources (SharePoint, Azure AI Search, Public URLs, Dataverse tables, uploaded PDFs).
4. **Actions & Plugins:** Connectors (REST APIs), Power Automate Cloud Flows, and Bot Framework Skills that perform real-world operations.
5. **Entity Recognition & Slot Filling:** Extracts parameters from user text (e.g., date, email, order number) into typed variables.

---

## 🧱 Anatomy of an Unpacked Copilot Solution

When you export a Copilot from Power Platform using the PAC CLI (`pac solution export`), it is unpacked into structured files:

```text
faq-support-agent/
├── Other/
│   ├── Customizations.xml     # Solution metadata, entities, and permissions
│   ├── Relationships.xml      # Entity relationship maps
│   └── Solution.xml           # Solution manifest, publisher, and version number
└── src/
    ├── bot/                   # Bot record metadata (display name, schema name)
    ├── botcomponents/         # Topics, dialog trees, AI configuration files
    │   ├── cr123_faqAgent.topic.Greeting.yaml
    │   ├── cr123_faqAgent.topic.Escalate.yaml
    │   ├── cr123_faqAgent.topic.SearchKnowledge.yaml
    │   └── cr123_faqAgent.topic.Fallback.yaml
    ├── environmentvariabledefinitions/
    └── connectionreferences/
```

### The Topic Definition (YAML Format)
Copilot Studio stores conversational logic in clean, human-readable YAML. For example, a greeting topic looks like this:

```yaml
kind: AdaptiveDialog
beginDialog:
  kind: OnRecognizedIntent
  id: main
  intent:
    triggerQueries:
      - "hello"
      - "hi there"
      - "good morning"
      - "help"

  actions:
    - kind: SendActivity
      id: sendActivity_welcome
      activity: "Hello! I am your AI Support Assistant. How can I assist you today?"

    - kind: Question
      id: question_category
      interruptionPolicy:
        allowInterruption: true
      prompt: "What department do you need help with?"
      entity:
        kind: ClosedListEntity
        items:
          - id: it_support
            displayName: "IT & Hardware"
          - id: hr_support
            displayName: "Human Resources"
          - id: billing
            displayName: "Billing & Invoices"
      variable: init:Topic.SelectedCategory

    - kind: ConditionGroup
      id: conditionGroup_route
      conditions:
        - id: cond_it
          condition: =Topic.SelectedCategory = "IT & Hardware"
          actions:
            - kind: BeginDialog
              id: jump_it_topic
              dialog: cr123_faqAgent.topic.ITSupport
```

---

## 🔄 Power Fx Expressions

Copilot Studio uses **Power Fx** (the same formula language used in Microsoft Excel and Power Apps) for logic, calculations, and data formatting.

Common examples:
- **String manipulation:** `="Welcome, " & User.DisplayName & "!"`
- **Date calculations:** `=Text(DateAdd(Today(), 7, TimeUnit.Days), "yyyy-MM-dd")`
- **Boolean conditions:** `=IsBlank(Topic.UserEmail) || Topic.RetryCount > 3`
- **JSON parsing:** `=ParseJson(Topic.ApiResponse).status`

---

## 🔐 Authentication Modes

Copilot Studio supports 3 main authentication models:

1. **No Authentication (Public):** The Copilot is deployed to a public website where any anonymous visitor can chat.
2. **Authenticate with Microsoft (Entra ID):** Ideal for internal Microsoft Teams or SharePoint Copilots. Users are automatically identified, giving access to user profile variables (`User.DisplayName`, `User.Email`, `User.Id`).
3. **Manual / Generic OAuth2:** Used to authenticate against third-party identity providers (Okta, Auth0, Google, custom IDPs) with PKCE and token exchange.
