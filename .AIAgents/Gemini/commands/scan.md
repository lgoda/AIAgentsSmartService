---
description: Build a structured project profile to guide agent behavior across product and engineering tasks.
arguments: Optional scope (product, backend, frontend, data, testing, devops, automation)
output: .ai/project-context.md and updated GEMINI.md notes
---

## User Input

```text
$ARGUMENTS
```

## Steps

1. Inspect repository metadata and source layout.
2. Document stack, architecture, integrations, and delivery workflow.
3. Capture coding standards, testing approach, and release conventions.
4. Create `.ai/project-context.md` from template. Emit all six `[context.<domain>]` sections (backend, frontend, data, testing, devops, automation); write `N/A — not detected` where there is no evidence.
5. Update `GEMINI.md` with project-aware guardrails.
6. Return unresolved ambiguities as `NEEDS CLARIFICATION`.

## Rules

- Keep language clear for technical and product stakeholders.
- Do not invent technologies not found in repo evidence.
- Make outputs reusable across future tasks.
- Docs-only repositories describing live platforms are expected: populate `[context.automation]` from the docs and do not invent code domains.
- Set `Stack skills` to the stack skills (listed in `GEMINI.md`) whose description matches technologies found in the repo, or `none`.
- If `.ai/project-context.md` exists, update it in place: add missing sections, refresh stale fields, never delete existing content.
