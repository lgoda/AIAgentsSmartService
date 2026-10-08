---
name: scan
description: Scan the repository and generate the full project context plus domain-specific context sections in .ai/project-context.md.
metadata:
  managed-by: aiagents
---

# Scan

## Arguments

Optional domain focus: `backend`, `frontend`, `data`, `testing`, `devops`, `automation`. Omit to generate all sections.

## Output

`.ai/project-context.md` — with populated `[context.<domain>]` sections.

## Goal

Produce an accurate, evidence-based project context that domain skills can load in full or in part.
Each `[context.<domain>]` section must be self-contained so a skill can load only its section
without needing the rest of the file.

## Steps

1. Scan repository structure: directories, config files, package manifests, CI files, README.
2. Extract per-domain evidence:
   - **backend**: language, framework, entry points, service modules, auth, external APIs, error handling, logging.
   - **frontend**: framework, state management, routing, component library, API layer, styling, build tooling.
   - **data**: databases, ORM/query layer, migration files, key models, caching, validation.
   - **testing**: test frameworks, test file patterns, coverage config, CI test gates.
   - **devops**: cloud provider, CI/CD platform, deployment scripts, environment names, secrets references, monitoring.
   - **automation**: live platforms in use and which is the system of record (workflow engines, voice or chat agent consoles, CRM, messaging, platform-side database functions), account or instance to MCP server mapping, publish policy, timezone, locale and phone country, change-record locations, docs routing. Docs-only repositories (no package manifest, docs describing live platforms) are expected: populate this section and mark code domains `N/A — not detected`.
3. Populate the top-level sections (Metadata, Stack, Architecture, Engineering Standards, Agent Instructions).
   - Set `Stack skills` to the stack skills (listed in `CLAUDE.md`) whose description matches technologies found in the repo, or `none`.
4. Populate each `[context.<domain>]` section with only the fields relevant to that domain.
   - If a domain has no evidence in the repo, write `N/A — not detected` for each field.
   - Mark uncertain fields as `NEEDS CLARIFICATION`.
5. Write the result to `.ai/project-context.md`.
   - If the file already exists, update it in place: add missing sections (for example `[context.automation]`), refresh stale fields, never delete existing sections or user-written content.
6. Update `CLAUDE.md` with any project-specific constraints discovered.
7. Return:
   - Confidence level per domain (high / medium / low)
   - List of assumptions made
   - Open questions marked `NEEDS CLARIFICATION`

## Domain skill mapping

| Skill    | Reads from project-context.md |
|----------|-------------------------------|
| backend  | `[context.backend]`           |
| frontend | `[context.frontend]`          |
| data     | `[context.data]`              |
| testing  | `[context.testing]`           |
| devops   | `[context.devops]`            |
| automation | `[context.automation]`        |

## Rules

- Prefer repository evidence over assumptions.
- Keep each `[context.<domain>]` section self-contained and under ~300 words.
- Do not repeat information across sections — cross-reference instead.
- Mark all assumptions explicitly.
- Re-run this skill (or target a specific domain) whenever the stack changes.
