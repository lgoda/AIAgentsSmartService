#!/usr/bin/env bash

# Lint framework skills for structure, size and leakage of client-specific data.
# Usage: ./.AIAgents/scripts/lint-skills.sh <skills-dir> [denylist-file]
#
# The denylist holds one extended regex per line (client names, ID patterns, hostnames).
# Keep it outside git; blank lines and lines starting with # are ignored.

set -uo pipefail

SKILLS_DIR="${1:?Usage: lint-skills.sh <skills-dir> [denylist-file]}"
DENYLIST="${2:-}"
MAX_SKILL_WORDS=600
MAX_REF_WORDS=1800
FAILED=0

fail() {
  echo "FAIL  $1: $2"
  FAILED=$((FAILED + 1))
}

frontmatter() {
  tr -d '\r' < "$1" | awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { exit } NR > 1 { print }'
}

words() {
  wc -w < "$1" | tr -d ' '
}

lint_frontmatter() {
  local dir="$1" name="$2" fm
  fm="$(frontmatter "$dir/SKILL.md")"
  [[ "$(echo "$fm" | sed -n 's/^name: *//p')" == "$name" ]] || fail "$name" "frontmatter name must equal the directory name"
  [[ -n "$(echo "$fm" | sed -n 's/^description: *\(.\)/\1/p')" ]] || fail "$name" "description missing"
  echo "$fm" | grep -q 'managed-by: aiagents' || fail "$name" "managed-by marker missing"
}

lint_sections() {
  local dir="$1" name="$2" file="$dir/SKILL.md"
  grep -qi '^## Hard rules' "$file" || fail "$name" "missing section: Hard rules"
  grep -qiE '^## (Workflow|Procedure)' "$file" || fail "$name" "missing section: Workflow or Procedure"
  grep -qi '^## Verification' "$file" || fail "$name" "missing section: Verification"
  grep -qi '^## Failure modes' "$file" || fail "$name" "missing section: Failure modes"
  if [[ -d "$dir/references" ]]; then
    grep -qi '^## References' "$file" || fail "$name" "missing section: References (index)"
  fi
}

lint_sizes() {
  local dir="$1" name="$2" ref count
  count="$(words "$dir/SKILL.md")"
  [[ "$count" -le "$MAX_SKILL_WORDS" ]] || fail "$name" "SKILL.md has $count words (max $MAX_SKILL_WORDS)"

  for ref in "$dir"/references/*.md; do
    [[ -f "$ref" ]] || continue
    count="$(words "$ref")"
    [[ "$count" -le "$MAX_REF_WORDS" ]] || fail "$name" "$(basename "$ref") has $count words (max $MAX_REF_WORDS)"
    grep -q '^Last verified:' "$ref" || fail "$name" "$(basename "$ref") lacks a 'Last verified:' line"
  done
}

lint_tool_names() {
  local dir="$1" name="$2" file
  grep -rnE 'TodoWrite|mcp__' "$dir" > /dev/null && fail "$name" "agent-specific tool name (TodoWrite or mcp__) found"
  grep -nE 'AskUserQuestion|ToolSearch' "$dir/SKILL.md" > /dev/null && fail "$name" "agent-specific tool name in SKILL.md"
  return 0
}

lint_denylist() {
  local dir="$1" name="$2" hits
  [[ -n "$DENYLIST" ]] || return 0
  hits="$(grep -rniE -f <(grep -vE '^\s*(#|$)' "$DENYLIST" | tr -d '\r') "$dir" 2> /dev/null | head -3)"
  [[ -z "$hits" ]] || fail "$name" "denylist match (first hits below)"$'\n'"$hits"
}

if [[ -n "$DENYLIST" && ! -f "$DENYLIST" ]]; then
  echo "Denylist not found: $DENYLIST" >&2
  exit 2
fi

COUNT=0
for dir in "$SKILLS_DIR"/*/; do
  dir="${dir%/}"
  [[ -f "$dir/SKILL.md" ]] || continue
  name="$(basename "$dir")"
  COUNT=$((COUNT + 1))
  lint_frontmatter "$dir" "$name"
  lint_sections "$dir" "$name"
  lint_sizes "$dir" "$name"
  lint_tool_names "$dir" "$name"
  lint_denylist "$dir" "$name"
done

if [[ "$COUNT" -eq 0 ]]; then
  echo "No skills found in $SKILLS_DIR" >&2
  exit 2
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo "Lint passed for $COUNT skill(s)."
else
  echo "$FAILED problem(s) found in $COUNT skill(s)."
  exit 1
fi
