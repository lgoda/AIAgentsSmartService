# Gemini Instructions

<!-- .AIAgents Autoload Start -->
Load command files from .gemini/commands/*.md

Domain skills available (load only the skill for your current task):
- .gemini/skills/backend/SKILL.md
- .gemini/skills/frontend/SKILL.md
- .gemini/skills/data/SKILL.md
- .gemini/skills/testing/SKILL.md
- .gemini/skills/devops/SKILL.md
- .gemini/skills/automation/SKILL.md

Stack skills — load in addition to the domain skill when the task touches that technology (see "Stack skills" in .ai/project-context.md):
- .gemini/skills/conversational-agents/SKILL.md
- .gemini/skills/crm/SKILL.md
- .gemini/skills/integrations/SKILL.md
- .gemini/skills/mcp-servers/SKILL.md
- .gemini/skills/messaging/SKILL.md
- .gemini/skills/n8n/SKILL.md
- .gemini/skills/voice-agents/SKILL.md

Live platform safety (applies to every task, with or without a skill loaded):
- Treat live platforms (workflows, voice agents, CRM, messaging, databases) as production.
- Confirm the target account or instance before any write. Never fall back to another account's tools.
- Read before write. Verify the effect afterwards, not just the API response.
- Never message, call or notify real people without explicit confirmation.
- Never copy secrets into files, logs or messages.
- Record every live change where [context.automation] says to.

Startup behavior (required):
1. Run `/scan` first to create/update `.ai/project-context.md`.
2. If `project-context.md` already exists, refresh it when stack, architecture, integrations, or standards change.
3. Before any task, load only the skill matching your domain (backend, frontend, data, testing, devops, automation).
4. Each skill specifies exactly which section of `project-context.md` to read — load only that section.
5. If critical info is missing, mark `NEEDS CLARIFICATION` and continue with safe defaults.

Recommended execution order:
1. `/scan`       → populate .ai/project-context.md
2. `/spec`       → define feature requirements — Gemini excels here (creates .ai/current automatically)
3. `/plan`       → architecture + phased implementation plan (reads .ai/current automatically)
4. `/tasks`      → execution task list — Gemini surfaces sequencing risks
5. `/implement`  → readiness review before handing off to Claude or Codex
6. `/review`     → deep gap analysis between spec intent and implementation — Gemini's strength
7. `/skill`      → create or edit a project-specific analysis skill

Navigation:
- `/status`      → pipeline snapshot with risk assessment
- `/switch`      → change active spec; highlights outstanding review issues on switch
- `/fix`         → root cause analysis + recommendation; add --trace for bug specs

Multi-agent workflow:
- Spec phase (/spec) → Gemini preferred — surfaces hidden requirements and risks
- Implementation review (/implement) → Gemini validates readiness, hands off to Claude/Codex
- Code review (/review) → Gemini's core strength — behavioral drift, edge case gaps
- Shared artifact: specs/<type>/<slug>/ — any agent picks up via .ai/current

Bootstrap command:
`./.AIAgents/scripts/bootstrap-commands.sh --repo . --agent all --mode copy`
<!-- .AIAgents Autoload End -->
