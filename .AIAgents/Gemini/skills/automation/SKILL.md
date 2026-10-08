---
name: automation
description: Analyze and review changes planned for live platforms — workflows, voice or chat agents, CRM and messaging configuration — for safety, rollback and verification before anyone applies them. Loads only [context.automation] from project-context.md.
metadata:
  managed-by: aiagents
---

# Skill: automation

## Metadata

- Agent: Gemini
- Version: 0.1.0
- Domain: automation
- Context section: `[context.automation]` in `project-context.md`

## Purpose

Review live-platform changes before they are applied. In many projects the repo holds only
documentation and the real system lives in platforms edited through MCP servers or APIs, so every
change is a production change. Focused on correctness, blast radius and verifiability.
Loads only the `[context.automation]` section.

## When to use

- Reviewing a proposed workflow, agent, flow, prompt, template or CRM change before it is applied
- Checking a change plan for missing rollback or verification
- Analyzing why a live automation misbehaved from executions, call logs or delivery status
- Assessing readiness of automation tasks before handing them to an implementing agent

Also load the stack skills listed under `Stack skills` in `.ai/project-context.md` that match the platform;
their hard rules and failure modes double as review criteria.

## Context loading (minimal)

Before starting, read only:
1. `[context.automation]` section from `.ai/project-context.md`
2. The docs named in its `Docs routing` field for this task

If `[context.automation]` is absent or empty, run `scan` or ask; mark it `NEEDS CLARIFICATION` and do not guess the target account. Do NOT load code-domain sections unless the change also touches repo code.
If the task touches a technology listed under `Stack skills`, also load that stack skill.

## Inputs

- The proposed change, diff or plan
- Optional: `specs/<feature>/tasks.md` for the task under review

## Workflow

Check that the plan covers each step of the live-change workflow, and flag every gap with a suggested fix:

1. **Target confirmed.** Platform, account or instance, and mapped tool or MCP server are named and match `[context.automation]`; no fallback to another account.
2. **Live state read narrowly.** The plan reads the platform, not only repo docs.
3. **Rollback point.** Exists, is located, and does not contain secrets.
4. **Minimal additive change.** The diff is small; shared components are changed additively only; the `Publish policy` is respected.
5. **Validation.** The platform's own validation is used where available.
6. **Re-read.** The plan re-reads the changed object instead of trusting the write response.
7. **Effect verified.** A designated test resource is used and delivery or outcome is checked, not just a 2xx or a green run.
8. **Change recorded.** Entry location, content and measured-versus-inferred marking are specified.

## Output

- Readiness verdict per step: green / amber / red
- Flags with a suggested resolution each
- Blast-radius note: shared components, other tenants, real people who could be contacted

## Constraints

- Analysis only; do not apply changes to platforms
- Flag any step that could message or call real people without explicit confirmation
- Flag any secret that would end up in a file, log or message
