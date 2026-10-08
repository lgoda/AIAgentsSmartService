# Agent Routing Guide

Folder names alone are not enough. Each agent needs explicit configuration to discover where skills and commands live.

## Structure in the target project (after bootstrap)

```
<project-root>/
├── .claude/
│   ├── commands/          ← loaded natively by Claude Code
│   └── skills/
├── .codex/
│   ├── commands/          ← loaded natively by Codex
│   └── skills/
├── .gemini/
│   ├── commands/          ← loaded natively by Gemini
│   └── skills/
├── .copilot/
│   ├── commands/          ← prompt templates (paste into Copilot Chat)
│   └── skills/
├── .github/
│   └── copilot-instructions.md  ← Copilot startup instructions
├── .ai/
│   └── project-context.md ← shared context file
├── CLAUDE.md              ← Claude startup instructions
├── AGENTS.md              ← Codex startup instructions
└── GEMINI.md              ← Gemini startup instructions
```

The `.AIAgents/` folder stays **only in this source repo** — it is not copied to target projects.

## Native agent paths (target project)

| Agent | Commands | Skills | Startup file |
|---|---|---|---|
| Claude | `.claude/commands/*.md` | `.claude/skills/*/SKILL.md` | `CLAUDE.md` |
| Codex | `.codex/commands/*.md` | `.codex/skills/*/SKILL.md` | `AGENTS.md` |
| Gemini | `.gemini/commands/*.md` | `.gemini/skills/*/SKILL.md` | `GEMINI.md` |
| Copilot | `.copilot/commands/*.md` ¹ | `.github/skills/*/SKILL.md` ² | `.github/copilot-instructions.md` |

¹ Copilot has no native slash commands — these are prompt templates to paste in Copilot Chat.
² Skills in `.github/skills/` are auto-discovered by Copilot Agent Mode (VS Code). In regular chat, paste manually.

## Source paths (this repo only)

| Agent | Commands (source) | Skills (source) |
|---|---|---|
| Claude | `.AIAgents/Claude/commands/*.md` | `.AIAgents/Claude/skills/*/SKILL.md` |
| Codex | `.AIAgents/Codex/commands/*.md` | `.AIAgents/Codex/skills/*/SKILL.md` |
| Gemini | `.AIAgents/Gemini/commands/*.md` | `.AIAgents/Gemini/skills/*/SKILL.md` |
| Copilot | `.AIAgents/Copilot/commands/*.md` | `.AIAgents/Copilot/skills/*/SKILL.md` → installs to `.github/skills/` |

## How to make it work

1. Run bootstrap — it copies source files into the correct native folders at the project root.
2. Each agent runtime scans only its own folder (`.claude/`, `.codex/`, `.gemini/`).
3. Skills live in `skills/<name>/SKILL.md` within the agent folder.
4. Commands are single `.md` files invoked by name (e.g. `scan.md` → `/scan`).

## Agent roles

| Agent | Strength | Best for |
|---|---|---|
| **Claude** | Broad reasoning + implementation | Features, refactors, complex tasks |
| **Codex** | Focused code generation | Implementation, tests, migrations |
| **Gemini** | Analysis + requirements | Design reviews, risk analysis, spec clarification |
| **Copilot** | IDE-integrated, model-agnostic | In-editor tasks, inline suggestions, quick fixes |

## Notes

- `project-context.md` lives in `.ai/` — neutral folder shared by all agents.
- Skills are loaded manually per task — agents do not auto-load all skills.
- Re-run bootstrap after adding new skills to propagate them to target projects.

## Skill discovery per agent (verified 2026-10-08)

| Agent | Native project skill paths | Installed by bootstrap to |
|---|---|---|
| Claude Code | `.claude/skills` | `.claude/skills` |
| Codex | `.agents/skills` only (not `.codex/skills`) | `.codex/skills`, listed explicitly in `AGENTS.md` |
| Gemini CLI | `.gemini/skills`, `.agents/skills` | `.gemini/skills` |
| Copilot | `.github/skills`, `.claude/skills`, `.agents/skills` | `.github/skills` |

Notes:
- Codex does not scan `.codex/skills`; it finds skills through the path list in `AGENTS.md`. Moving to `.agents/skills` would also expose them to Gemini and Copilot under the same names, so it is a separate decision.
- With `--agent all`, Copilot sees both `.github/skills` and `.claude/skills`; same-named skills appear twice.
- Re-bootstrap overwrites only framework-managed skills: those with `managed-by: aiagents` in their frontmatter, or identical to a version shipped before the marker existed (`scripts/legacy-skill-checksums.txt`). Any other skill with the same name is project-authored: it is skipped with a warning and not listed under "Stack skills".

## Shared stack skills

`.AIAgents/_shared/skills/<name>/` (with optional `references/`) is installed into every selected agent. A same-named folder in `.AIAgents/<Agent>/skills/` overrides it for that agent.
The startup files list them under "Stack skills"; `scan` records the ones that apply in `.ai/project-context.md`.

## Install source

`install.sh` clones this fork by default. Use `--source <git-url>` to install from another repository (for example the upstream project).
