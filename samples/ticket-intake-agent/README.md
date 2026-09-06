# Ticket intake agent: a confirmed draft, not a fake submission

This **standard-harness** Copilot Studio sample collects a fictional symptom,
validates a category, shows a preview, and accepts **confirm** or **cancel**.
Confirmation displays a draft only. No backend is called and no ticket is created.
The separate OpenAPI file is an editable connector design exercise, not a dependency.

| File | Supported destination |
|---|---|
| [instructions.txt](instructions.txt) | Agent **Overview > Instructions > Edit** |
| [draft-ticket.yaml](topics/draft-ticket.yaml) | One new topic's **More (...) > Open code editor** |
| [lab-tickets.swagger.json](connector/lab-tickets.swagger.json) | Optional custom connector **Import an OpenAPI file**, not an agent import |
| [examples.json](examples.json) | Manual test cases, not a product import format |

## Setup the usable draft agent

1. Create a blank agent named **Lab Ticket Draft** in a Dev environment. Keep
   tenant-required authentication and policies. Do not add a real ticket connector.
2. Paste `instructions.txt` into **Overview > Instructions > Edit** and save.
3. Create a blank topic named **Draft ticket** under **Topics**. Open **More (...) >
   Open code editor**, replace the entire topic with `topics\draft-ticket.yaml`,
   save, and return to the visual canvas. No component IDs need replacing.
4. Inspect the canvas: three variable resets, summary question and validation,
   category question and validation, draft preview, confirmation question, then
   confirmed/not-confirmed messages. All questions identify the **user's entire
   response** (strings), not generated multiple-choice entity values.
   In each Question's **Properties > Question behavior**, choose **Ask every time**.
   Under **Entity recognition > No valid entity found**, choose **Set variable to
   empty (no value)**, not escalation or a default value. The following conditions
   then stop the draft. Under **Interruptions**, turn off **Allow switching to
   another topic** for this exercise so the topic handles its own cancel responses.
   Confirm that the confirmation question is visibly asked before its branch.
5. Use classic orchestration for a trigger-phrase-first exercise, or generative
   orchestration with the supplied topic description. Agent-level generative
   instructions do not replace the explicit topic nodes. If using generative
   routing, insert a `/` reference to **Draft ticket** in the instructions via
   the resource picker. No knowledge source or web search is needed.
6. In **Test**, start a new conversation for each case in `examples.json`.
   Begin with **draft a lab ticket**, **Fictional monitor flickers**, **hardware**,
   **confirm**. You should see a preview and then **Confirmed draft only** with
   the same values and an explicit no-ticket/no-contact statement.
7. Test cancellation at each question, invalid categories, and **maybe** at
   confirmation. Also enter a 201-character summary: it must stop before category.
   Try whitespace-only text: it must not reach confirmation (the channel may
   refuse to send it). Run the `restart` case in a single conversation: old values
   and confirmation must not be reused. Inspect the topic trace, not just wording.

Use lowercase `hardware`, `software`, `access`, and `confirm` exactly. Unexpected
input stops rather than guessing or silently correcting it. To edit, cancel and
start again. System topics can intercept cancellation or other utterances;
verify they never imply submission or handoff. Cancellation is not deletion of
conversation history. This exercise does not implement PII detection or redact
transcripts: use invented data only.

## Optional connector design exercise (no deployed endpoint)

The contract describes **CreateLabTicket**, `POST /lab/tickets`. The host
`tickets.example.invalid` deliberately cannot resolve. No server, credentials,
connection, or tool binding is supplied. Leave it unwired to complete the draft lab.

In Power Apps or Power Automate, open a Dev **Solution > New > Automation >
Custom connector > Import an OpenAPI file** and select the JSON. Inspect **General**
(host/base path), **Security** (no authentication, lab placeholder only), and
**Definition** (`CreateLabTicket`). Do not test against the placeholder or weaken
tenant policy to save it. Importing a definition does not deploy an API. No-auth
is not a production recommendation; policy may correctly block this exercise.

| Contract field | Meaning for a future lab implementation |
|---|---|
| Request `summary` | 1-200 characters; server also rejects whitespace-only text |
| Request `category` | Exactly `hardware`, `software`, or `access` |
| Request `confirmed` | Boolean `true`; requires explicit confirmation of the current details, not an agent default |
| HTTP `201` | Required `ticketId`, `status: created`, `summary`, `category`; only after backend persistence |
| HTTP `400` | `code: invalid_request`, safe `message`; no success message |
| HTTP `503` | `code: unavailable`, safe `message`; creation not confirmed |

Only after a separately approved API and authentication design exist should a
maker change the host/security, create a connection, and add a tool or flow **inside
the confirmed branch**, binding the summary and category variables. Require HTTP
201, a nonempty backend `ticketId`, and `status = created` before acknowledging even
a lab ticket. Timeouts, malformed results, and other errors mean creation is not
confirmed; do not automatically retry a create after an ambiguous timeout (there
is no idempotency mechanism in this minimal contract). Prompt instructions and
`confirmed: true` are not authorization or backend validation.

## Validation boundary and promotion

The topic's node patterns are sourced from pinned Microsoft examples; local
checks parse YAML and JSON and inspect invariants. **Tenant save/import, Power Fx
execution, connector acceptance, orchestration, and channels are untested.**
Resolve checker errors and run all cases in Dev before publication.
These are single-topic/config assets, not a whole-agent or Dataverse solution.
Promotion still requires a genuine export and the [ALM process](../../docs/02-alm-and-automation.md).
Do not copy connector settings into the intentionally blocked deployment defaults.
See [sources and provenance](../SOURCES.md).
