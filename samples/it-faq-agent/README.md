# IT FAQ agent: paste, upload, and test

Build a small **standard-harness** Copilot Studio agent that answers from five
fictional approved FAQs. No connector, Azure resource, credentials, or PAC CLI
is needed. You still need access to create an agent in a Dev environment;
file knowledge requires Dataverse search and sufficient storage.

| File | Supported destination |
|---|---|
| [instructions.txt](instructions.txt) | Agent **Overview > Instructions > Edit** |
| [approved-it-faq.md](knowledge/approved-it-faq.md) | **Knowledge > Add knowledge**, upload a file |
| [demo-scope.yaml](topics/demo-scope.yaml) | One new topic's **More (...) > Open code editor** |
| [examples.json](examples.json) | Manual test cases below, not a product import format |

## Setup

1. Create a blank agent named **Northstar Lab IT FAQ** in a Dev environment.
   Keep tenant-required authentication and policies; use only fictional data.
2. Paste all of `instructions.txt` into **Overview > Instructions > Edit** and
   save. These instructions describe behavior; they do not add knowledge.
3. In **Knowledge > Add knowledge**, upload `knowledge\approved-it-faq.md`.
   Use the name **Northstar Lab IT FAQ** and description
   **Fictional approved IT policies: help desk hours, software requests, VPN,
   account recovery, and loaner laptops. No live operations or service levels.**
   Select **Add to agent**, and wait for the knowledge source to be ready.
   Do not upload this README or the test cases as knowledge.
4. Under **Settings > Generative AI**, select generative orchestration.
   Turn off **Allow ungrounded responses** and **Use information from the web**
   (also called **Web Search**). Do not add other knowledge sources for this lab.
   Leave built-in answer rendering/citations intact: do not copy an answer
   variable into a custom message or instruct the agent to reformat citations.
5. Under **Topics**, add a blank topic named **Demo scope**. Open its code editor,
   replace the entire topic with `topics\demo-scope.yaml`, save, and return to the
   visual canvas. Confirm there is a trigger and one Message node. This topic
   only explains scope; the uploaded file supplies the actual FAQ answers.
6. Open **Test**, start a new conversation per case in `examples.json`, and compare
   with `expected`. For FAQ answers, inspect the built-in source citation and
   confirm it points to **Northstar Lab IT FAQ** and supports the answer. A source
   marker alone does not prove that every claim is correct. Uploaded-file citations
   do not promise a public clickable document URL.

Try **When is the help desk open?** first: expect Monday-Friday, 09:00-17:00 UTC.
Try **Is it open Saturday?**: expect closed. Try **What is the guaranteed response
time?**: expect no invented SLA. If there is no grounded answer, a built-in
fallback is acceptable; do not enable ungrounded answers just to hide the failure.
Follow-up questions may also fall back when the orchestrator doesn't retrieve
knowledge again. Check source readiness, settings, and the test trace.

## Edit and promote

Edit the FAQ facts and instructions together, re-upload the changed file, wait
for indexing, and rerun the examples. Use only content approved for everyone who
can reach the agent; an uploaded file is not per-user SharePoint permission trimming.

The YAML is **single-topic code-editor content**, not a whole-agent or Dataverse
solution import. Node syntax was compared with pinned Microsoft samples; tenant
save, runtime, channel, and citation behavior remain untested. Resolve any
topic checker errors in Dev before publication. For promotion, create and export
a genuine solution using the [ALM guide](../../docs/02-alm-and-automation.md).
See [sources and provenance](../SOURCES.md).
