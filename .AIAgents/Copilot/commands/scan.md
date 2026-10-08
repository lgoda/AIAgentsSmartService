---
description: Profile the repository and generate agent context with stack, architecture, integrations, and engineering standards.
arguments: Optional focus (backend, frontend, data, testing, devops, automation)
output: .ai/project-context.md
usage: Paste this prompt into Copilot Chat
---

## Prompt

Scan this repository and generate `.ai/project-context.md`.

Steps:
1. Detect languages, frameworks, package managers, and services from repository files.
2. Identify connections: databases, queues, external APIs, auth providers, cloud services.
3. Infer architecture and module boundaries from code and config.
4. Write `.ai/project-context.md` with sections: `[context.backend]`, `[context.frontend]`, `[context.data]`, `[context.testing]`, `[context.devops]`, `[context.automation]`. Write `N/A — not detected` where there is no evidence.
5. Return a summary of findings and any items marked `NEEDS CLARIFICATION`.

Rules:
- Prefer facts from files over assumptions.
- Mark uncertain items as `NEEDS CLARIFICATION`.
- Keep context concise and actionable.
- Docs-only repositories describing live platforms are expected: populate `[context.automation]` from the docs and do not invent code domains.
- Set `Stack skills` to the stack skills (listed in `.github/copilot-instructions.md`) whose description matches technologies found in the repo, or `none`.
- If `.ai/project-context.md` exists, update it in place: add missing sections, refresh stale fields, never delete existing content.
