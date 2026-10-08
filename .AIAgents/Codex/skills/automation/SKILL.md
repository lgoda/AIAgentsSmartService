---
name: automation
description: Handle changes made on live platforms rather than in repo files — workflows, voice or chat agents, CRM and messaging configuration, platform-side database functions. Enforces the live-change safety workflow. Loads only [context.automation] from project-context.md.
metadata:
  managed-by: aiagents
---

# Skill: automation

## Metadata

- Agent: Codex
- Version: 0.1.0
- Domain: automation
- Context section: `[context.automation]` in `project-context.md`

## Purpose

Change live platforms safely. In many projects the repo holds only documentation and the real system
lives in platforms (workflow engines, voice agent consoles, CRMs, messaging providers) edited through
MCP servers or APIs. Every such change is a production change.
Loads only the `[context.automation]` section — not the full project context.

## When to use

- Editing a workflow, voice agent, conversation flow, prompt, template or CRM configuration on a platform
- Changing database functions or data that a platform reads live
- Investigating why a live automation misbehaved (executions, call logs, delivery status)
- Preparing a rollback or a change record for any of the above

Also load the stack skills listed under `Stack skills` in `.ai/project-context.md` that match the platform.

## Context loading (minimal)

Before starting, read only:
1. `[context.automation]` section from `.ai/project-context.md`
2. The docs named in its `Docs routing` field for this task

If `[context.automation]` is absent or empty, run `scan` or ask; mark it `NEEDS CLARIFICATION` and do not guess the target account. Do NOT load code-domain sections unless the task also changes repo code (split that into its own task).
If the task touches a technology listed under `Stack skills`, also load that stack skill.

## Inputs

- The change requested and the platform object it targets
- Optional: `specs/<feature>/tasks.md` for the current task

## Workflow

1. **Confirm the target.** Identify platform, account or instance, and the tool or MCP server mapped to it in `[context.automation]`. If the mapping is missing or the mapped server is unavailable, stop and ask. Never fall back to another account's tools.
2. **Read live state narrowly.** Structure first, then only the parts the change needs. Treat repo docs as hints; the platform is the system of record.
3. **Create a rollback point.** Inactive copy, previous version id, or a dated export with secrets removed. State where it is.
4. **Prepare the minimal additive change.** Show the diff. Apply it only if the user asked you to, or `Publish policy` is `agent`; otherwise leave a draft for a human to publish.
5. **Validate** with the platform's own validation where one exists.
6. **Re-read the changed object.** Never trust the write response; some platforms report success and change nothing.
7. **Verify the effect.** Run a test through a designated test resource, then check status or delivery. A 2xx or a green run does not prove the behavior.
8. **Record the change** at the location named in `Change-record locations`: what, why, how verified, rollback point. Mark facts as measured or inferred.

## Output

- What changed on which account, and the rollback point
- Verification evidence (execution, call or message ids)
- Change-record entry written
- Flags for impact on shared components or other tenants

## Constraints

- Treat shared components as high blast radius: additive changes only
- Never message, call or notify real people without explicit confirmation
- Never copy secrets into files, logs or messages; reference where they live
- Do not edit through the API an object someone has open in the platform UI
- One concern per task; code changes go to the matching code domain
