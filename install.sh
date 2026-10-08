#!/usr/bin/env bash

# AIAgents installer
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/lgoda/AIAgentsSmartService/main/install.sh)
#   bash <(curl -fsSL https://raw.githubusercontent.com/lgoda/AIAgentsSmartService/main/install.sh) --agent claude
#   bash <(curl -fsSL https://raw.githubusercontent.com/lgoda/AIAgentsSmartService/main/install.sh) --agent all --mode link
#   bash <(curl -fsSL ...install.sh) --source https://github.com/DiegoBoni/AIAgents.git   # install upstream instead

set -euo pipefail

REPO_URL="https://github.com/lgoda/AIAgentsSmartService.git"
TMP_DIR="$(mktemp -d)"
TARGET="$(pwd)"
AGENT="all"
MODE="copy"

# ── parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent) AGENT="$2"; shift 2 ;;
    --mode)  MODE="$2";  shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --source) REPO_URL="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: install.sh [--agent claude|codex|gemini|copilot|all] [--mode copy|link] [--target PATH] [--source GIT_URL]"
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# ── validate ──────────────────────────────────────────────────────────────────
case "$AGENT" in codex|gemini|claude|copilot|all) ;; *)
  echo "Invalid --agent: $AGENT  (use: claude | codex | gemini | copilot | all)" >&2; exit 1 ;;
esac

case "$MODE" in copy|link) ;; *)
  echo "Invalid --mode: $MODE  (use: copy | link)" >&2; exit 1 ;;
esac

if [[ ! -d "$TARGET" ]]; then
  echo "Target directory does not exist: $TARGET" >&2; exit 1
fi

# ── clone ─────────────────────────────────────────────────────────────────────
echo ""
echo "  AIAgents installer"
echo "  ──────────────────"
echo "  Target : $TARGET"
echo "  Agent  : $AGENT"
echo "  Mode   : $MODE"
echo "  Source : $REPO_URL"
echo ""

echo "Cloning AIAgents source..."
git clone --quiet --depth 1 "$REPO_URL" "$TMP_DIR"

# ── bootstrap ─────────────────────────────────────────────────────────────────
echo "Running bootstrap..."
bash "$TMP_DIR/.AIAgents/scripts/bootstrap-commands.sh" \
  --repo "$TARGET" \
  --agent "$AGENT" \
  --mode "$MODE"

# ── cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"

# ── done ──────────────────────────────────────────────────────────────────────
echo ""
echo "Done. AIAgents installed in: $TARGET"
echo ""
echo "Next steps:"
echo "  1. Open $TARGET in your AI agent"
echo "  2. Run /scan         →  scans the repo and populates .ai/project-context.md"
echo "  3. Run /spec <desc>  →  define feature requirements (multi-agent: spec-writer role)"
echo "  4. Run /plan         →  architecture and phased implementation plan"
echo "  5. Run /tasks        →  execution task list with dependencies"
echo "  6. Run /implement    →  execute tasks domain-by-domain with progress tracking"
echo ""
echo "  Optional: /skill <name> <domain>  →  create a project-specific skill"
echo "  Optional: /fix <desc> <file>      →  minimal bug fix without spec/plan/tasks"
echo ""
