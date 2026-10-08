# Claude Instructions

Load command files from `.claude/commands/*.md`.

<!-- .AIAgents Autoload Start -->
Slash commands (legacy, kept for compatibility):
Load command files from .claude/commands/*.md

Workflow skills — invoke by name to execute a pipeline step:
- scan         → populate .ai/project-context.md
- spec         → define feature requirements (creates .ai/current)
- plan         → architecture + phased implementation plan
- tasks        → execution task list with dependencies
- implement    → execute tasks domain-by-domain with progress tracking
- spec-review  → validate implementation against spec acceptance criteria
- fix          → minimal bug fix (add --trace for bug spec traceability)
- status       → pipeline snapshot — stage, task counts, next step
- switch       → change active spec without re-running spec
- mkskill      → create or update a project-specific skill
- harness      → configure Claude Code hooks and permissions

Domain skills — load only the skill matching your current task:
- .claude/skills/backend/SKILL.md
- .claude/skills/frontend/SKILL.md
- .claude/skills/data/SKILL.md
- .claude/skills/testing/SKILL.md
- .claude/skills/devops/SKILL.md
- .claude/skills/automation/SKILL.md

Stack skills — load in addition to the domain skill when the task touches that technology (see "Stack skills" in .ai/project-context.md):
- .claude/skills/conversational-agents/SKILL.md
- .claude/skills/crm/SKILL.md
- .claude/skills/integrations/SKILL.md
- .claude/skills/mcp-servers/SKILL.md
- .claude/skills/messaging/SKILL.md
- .claude/skills/n8n/SKILL.md
- .claude/skills/voice-agents/SKILL.md

Live platform safety (applies to every task, with or without a skill loaded):
- Treat live platforms (workflows, voice agents, CRM, messaging, databases) as production.
- Confirm the target account or instance before any write. Never fall back to another account's tools.
- Read before write. Verify the effect afterwards, not just the API response.
- Never message, call or notify real people without explicit confirmation.
- Never copy secrets into files, logs or messages.
- Record every live change where [context.automation] says to.

Startup behavior (required):
1. Invoke the `scan` skill first to create/update `.ai/project-context.md`.
2. If `project-context.md` already exists, refresh it when stack, architecture, integrations, or standards change.
3. Before any task, load only the domain skill matching your work (backend, frontend, data, testing, devops, automation).
4. Each domain skill specifies exactly which section of `project-context.md` to read — load only that section.
5. If critical info is missing, mark `NEEDS CLARIFICATION` and continue with safe defaults.

Multi-agent workflow:
- Spec phase (spec + plan) → best handled by an analysis-focused agent (Gemini, Claude)
- Implementation phase (implement) → best handled by a code-generation agent (Claude, Codex)
- Shared artifact: specs/<feature>/ — any agent can hand off to another via these files

Bootstrap command:
`./.AIAgents/scripts/bootstrap-commands.sh --repo . --agent all --mode copy`
<!-- .AIAgents Autoload End -->

## Project constraints

- This repo is the framework source. Edit `.AIAgents/<Agent>/...`, then re-run bootstrap; root `.claude/`, `.codex/`, `.gemini/`, `.copilot/` are generated copies.
- Never edit inside the Autoload Start/End block above; bootstrap regenerates it.
- Keep Claude, Codex, Gemini and Copilot variants consistent when a change applies to all of them.
- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`). Line endings: LF (see `.gitattributes`).
