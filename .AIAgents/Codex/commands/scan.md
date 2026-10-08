---
description: Profile the repository and generate agent context with stack, architecture, integrations, and engineering standards.
arguments: Optional focus (backend, frontend, data, testing, devops, automation)
output: .ai/project-context.md and updated AGENTS.md notes
---

## User Input

```text
$ARGUMENTS
```

## Steps

1. Scan repository files to detect languages, frameworks, package managers, and services.
2. Identify connections: databases, queues, external APIs, auth providers, cloud services.
3. Infer architecture and module boundaries from code and config.
4. Generate `.ai/project-context.md` using the shared template. Emit all six `[context.<domain>]` sections (backend, frontend, data, testing, devops, automation); write `N/A — not detected` where there is no evidence.
5. Update `AGENTS.md` with concise project-specific operating rules.
6. Return findings, assumptions, and gaps requiring clarification.

## Rules

- Prefer facts from repository files over assumptions.
- Mark uncertain items as `NEEDS CLARIFICATION`.
- Keep context concise and actionable.
- Docs-only repositories describing live platforms are expected: populate `[context.automation]` from the docs and do not invent code domains.
- Set `Stack skills` to the stack skills (listed in `AGENTS.md`) whose description matches technologies found in the repo, or `none`.
- If `.ai/project-context.md` exists, update it in place: add missing sections, refresh stale fields, never delete existing content.
