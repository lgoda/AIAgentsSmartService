---
name: backend
description: Handle backend implementation tasks — endpoints, business logic, services, auth, and integrations. Loads only [context.backend] from project-context.md.
metadata:
  managed-by: aiagents
---

# Skill: backend

## Metadata

- Agent: Claude
- Version: 0.1.0
- Domain: backend
- Context section: `[context.backend]` in `project-context.md`

## Purpose

Handle backend implementation tasks: endpoints, business logic, services, auth, and integrations.
Loads only the `[context.backend]` section — not the full project context — to minimize token usage.

## When to use

- Implementing or modifying API endpoints
- Writing or refactoring business logic / services
- Integrating external APIs or third-party services
- Reviewing or fixing auth and authorization flows
- Adding middleware, validation, or error handling

## Context loading (minimal)

Before starting, read only:
1. `[context.backend]` section from `.ai/project-context.md`
2. The specific file(s) involved in the task

Do NOT load frontend, data migration, or devops sections unless explicitly required.
If the task touches a technology listed under `Stack skills` in `.ai/project-context.md`, also load that stack skill (open its `references/` only where its index points). If a listed stack skill is not installed, say so and continue with the domain rules.

## Inputs

- Task description or file path(s) to modify
- Optional: related spec file at `specs/<feature>/spec.md`

## Workflow

1. Read `[context.backend]` from `.ai/project-context.md`.
2. Identify the specific module, service, or endpoint to change.
3. Read only the relevant source files.
4. Implement minimal, focused changes aligned with backend conventions.
5. Verify error handling, input validation, and auth guards are in place.
6. Return a concise summary: what changed, why, and any follow-up needed.

## Output

- Code change(s) with inline explanation
- List of files modified
- Flags for downstream impact (data layer, frontend contract, tests)

## Constraints

- Do not modify frontend or migration files in the same task
- Follow the auth strategy defined in `[context.backend]`
- Keep changes reviewable: one concern per task
