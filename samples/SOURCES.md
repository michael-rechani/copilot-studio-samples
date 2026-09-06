# Sample sources and provenance

Checked **2026-09-05**. The instructions, fictional FAQ, test cases, contract, and
conversation text are original repository content. The topic structure adapts
small node patterns from Microsoft's MIT-licensed samples, not tenant exports.
No upstream flow IDs, model IDs, private data, or solution metadata were copied.

## Topic node syntax

Pinned Microsoft repository revision:
`9976436e68fa44f31322fef7a851de649052cb23`.

| Source | Patterns used in our two topics |
|---|---|
| [WorkdayGivePeerFeedback/topic.yaml](https://github.com/microsoft/CopilotStudioSamples/blob/9976436e68fa44f31322fef7a851de649052cb23/EmployeeSelfServiceAgent/Workday/EmployeeScenarios/WorkdayGivePeerFeedback/topic.yaml) | `AdaptiveDialog`, `modelDescription`, `OnRecognizedIntent`, `intent.triggerQueries`, `Question` with `StringPrebuiltEntity` and `Topic` variables, `ConditionGroup`, `conditions`/`elseActions`, `SendActivity`, variable interpolation, empty `inputType`/`outputType` |
| [EmployeeCreateFacilitiesManagementTicket/topic.yaml](https://github.com/microsoft/CopilotStudioSamples/blob/9976436e68fa44f31322fef7a851de649052cb23/EmployeeSelfServiceAgent/Facilities/EmployeeCreateFacilitiesManagementTicket/topic.yaml) | `SetVariable` with `variable`/Power Fx `value`, string equality in confirmation branches |

The sample content simplifies these patterns: no flows, cards, external dialogs,
model actions, or tenant identifiers. Our Power Fx guards use strings, `Blank`,
`IsBlank`, `Trim`, `Lower`, `Len`, and boolean operators; local YAML parsing does
not execute those expressions. See Microsoft's
[Power Fx in topics](https://learn.microsoft.com/en-us/microsoft-copilot-studio/advanced-power-fx)
and [formula reference](https://learn.microsoft.com/en-us/power-platform/power-fx/formula-reference-overview).

## Product setup and connector format

| Official Microsoft source | What it establishes |
|---|---|
| [Topic code editor](https://learn.microsoft.com/en-us/microsoft-copilot-studio/guidance/topics-code-editor) | Paste YAML into one topic via More > Open code editor; save and test in Studio |
| [Question nodes](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-ask-a-question) | Stored responses, question skip behavior, recognition and interruption settings |
| [Agent instructions](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-instructions) | Overview instruction editing and resource picker; do not override system citation formatting |
| [File knowledge](https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-add-file-upload) | Standard harness, Markdown upload, Dataverse search prerequisite, source name/description |
| [Knowledge settings](https://learn.microsoft.com/en-us/microsoft-copilot-studio/knowledge-copilot-studio) | Ungrounded response and web search settings, grounding limitations and channel-dependent citations |
| [OpenAPI custom connector](https://learn.microsoft.com/en-us/connectors/custom-connectors/define-openapi-definition) | OpenAPI **2.0**, JSON import, `host`, `basePath`, `schemes`, `operationId`, body parameters and response schemas |
| [OpenAPI 2.0 specification](https://spec.openapis.org/oas/v2.0.html) | Original lab contract's `$ref`, definitions, required properties, enums and string constraints |

Knowledge settings documentation and instruction guidance differ on whether to
add citation wording to instructions. This lab takes the conservative path:
leave the built-in renderer and citation behavior unchanged. Uploaded-file
citations are **not a promise of a public clickable document URL**; inspect the
source attribution available in the chosen channel.

Schema comparison is not product certification. These assets have not been saved
or imported in a tenant. Perform the README's manual cases in Dev, then export a
genuine Dataverse solution before promotion.

## Upstream license notice for adapted topic patterns

[Microsoft sample license at the pinned revision](https://github.com/microsoft/CopilotStudioSamples/blob/9976436e68fa44f31322fef7a851de649052cb23/LICENSE):

```text
MIT License

Copyright (c) Microsoft Corporation.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE
```
