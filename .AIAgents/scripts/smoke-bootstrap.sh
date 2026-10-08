#!/usr/bin/env bash

# Smoke test for bootstrap-commands.sh. Runs against a temp copy of the module with fixture skills.
# Usage: ./.AIAgents/scripts/smoke-bootstrap.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_MODULE="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP="$(mktemp -d)"
MOD="$TMP/module/.AIAgents"
FAILED=0

trap 'rm -rf "$TMP"' EXIT

check() {
  local desc="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "PASS  $desc"
  else
    echo "FAIL  $desc"
    FAILED=$((FAILED + 1))
  fi
}

# agent source dir -> skills dir in the target project
AGENT_DIRS="Claude:.claude/skills Codex:.codex/skills Gemini:.gemini/skills Copilot:.github/skills"

# Portable in-place edit (BSD and GNU sed differ on -i).
edit_in_place() {
  sed "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

write_fixture_skill() {
  local dir="$1"
  local name="$2"
  mkdir -p "$dir/$name/references"
  printf -- '---\nname: %s\ndescription: fixture\nmetadata:\n  managed-by: aiagents\n---\n\n# %s\n' "$name" "$name" > "$dir/$name/SKILL.md"
  printf '# ref\nLast verified: 2026-01-01\n' > "$dir/$name/references/ref.md"
}

bootstrap() {
  local target="$1"
  shift
  mkdir -p "$target"
  bash "$MOD/scripts/bootstrap-commands.sh" --repo "$target" "$@"
}

symlinks_supported() {
  ln -sfn "$TMP/probe-src" "$TMP/probe-link" 2>/dev/null
  [[ -L "$TMP/probe-link" ]]
}

skills_match_source() {
  local target="$1"
  local pair agent_dir dest
  for pair in $AGENT_DIRS; do
    agent_dir="${pair%%:*}"
    dest="$target/${pair#*:}"
    for skill in "$MOD/$agent_dir/skills"/*/; do
      [[ -f "${skill}SKILL.md" ]] || continue
      diff -r "$skill" "$dest/$(basename "$skill")" || return 1
    done
  done
}

shared_installed_everywhere() {
  local target="$1"
  local name="$2"
  local pair
  for pair in $AGENT_DIRS; do
    diff -r "$MOD/_shared/skills/$name" "$target/${pair#*:}/$name" || return 1
  done
}

setup_module() {
  mkdir -p "$TMP/module"
  cp -r "$SRC_MODULE" "$MOD"
  write_fixture_skill "$MOD/_shared/skills" "zz-fixture"
}

test_copy_install() {
  local t="$TMP/copy"
  bootstrap "$t" --agent all --mode copy > "$TMP/copy.log" 2>&1
  local rc=$?
  check "AC1 bootstrap --agent all exits 0" test "$rc" -eq 0
  check "AC1 bootstrap creates .ai/project-context.md" test -f "$t/.ai/project-context.md"
  check "AC1 agent skills match their sources" skills_match_source "$t"
  check "AC1/AC2 shared skill with references installed identically in all agents" shared_installed_everywhere "$t" "zz-fixture"
}

test_override() {
  local t="$TMP/override"
  mkdir -p "$MOD/Claude/skills/zz-override"
  write_fixture_skill "$MOD/_shared/skills" "zz-override"
  printf -- '---\nname: zz-override\ndescription: claude-only\nmetadata:\n  managed-by: aiagents\n---\n' > "$MOD/Claude/skills/zz-override/SKILL.md"
  bootstrap "$t" --agent all --mode copy > /dev/null 2>&1
  check "override: Claude gets its own variant" grep -q "claude-only" "$t/.claude/skills/zz-override/SKILL.md"
  check "override: Codex gets the shared variant" grep -q "description: fixture" "$t/.codex/skills/zz-override/SKILL.md"
  rm -rf "$MOD/Claude/skills/zz-override" "$MOD/_shared/skills/zz-override"
}

test_link_mode() {
  local t="$TMP/link"
  bootstrap "$t" --agent all --mode link > "$TMP/link.log" 2>&1
  if symlinks_supported; then
    check "AC3 shared skill files are symlinks to the source" test -L "$t/.claude/skills/zz-fixture/references/ref.md"
  else
    check "AC3 unsupported symlinks: exactly one warning" test "$(grep -c 'symlinks are not supported' "$TMP/link.log")" -eq 1
  fi
  check "AC3 link mode content readable" grep -q "zz-fixture" "$t/.claude/skills/zz-fixture/SKILL.md"
}

test_collision_guard() {
  local t="$TMP/collide" s="$TMP/collide/.claude/skills"
  write_fixture_skill "$MOD/_shared/skills" "zz-collide"
  mkdir -p "$s/zz-collide" "$s/zz-fixture" "$s/backend" "$s/frontend"
  printf 'project-authored\n' > "$s/zz-collide/SKILL.md"
  printf -- '---\nmetadata:\n  managed-by: aiagents\n---\nstale\n' > "$s/zz-fixture/SKILL.md"
  printf 'my own backend skill\n' > "$s/backend/SKILL.md"
  printf -- '---\nname: frontend\ndescription: mine\n---\nFramework skills carry managed-by: aiagents.\n' > "$s/frontend/SKILL.md"
  bootstrap "$t" --agent claude --mode copy > "$TMP/collide.log" 2>&1
  check "AC6 unmarked project skill left unchanged" test "$(cat "$s/zz-collide/SKILL.md")" = "project-authored"
  check "AC6 warning names the skipped skill" grep -q "zz-collide" "$TMP/collide.log"
  check "marked skill is updated" grep -q "# zz-fixture" "$s/zz-fixture/SKILL.md"
  check "project skill with a framework name is kept" test "$(cat "$s/backend/SKILL.md")" = "my own backend skill"
  check "marker mentioned only in the body does not count" grep -q "description: mine" "$s/frontend/SKILL.md"
  check "skipped stack skill is not listed in CLAUDE.md" bash -c "! grep -q 'skills/zz-collide/SKILL.md' '$t/CLAUDE.md'"
  rm -rf "$MOD/_shared/skills/zz-collide"
}

# Content of a SKILL.md as first shipped, before the managed marker existed.
legacy_skill_content() {
  local repo="$SRC_MODULE/.." path=".AIAgents/Claude/skills/data/SKILL.md"
  git -C "$repo" show "$(git -C "$repo" rev-list HEAD -- "$path" | tail -1):$path"
}

test_link_then_copy() {
  local t="$TMP/relink"
  if ! symlinks_supported; then
    echo "SKIP  link then copy: symlinks unsupported on this host"
    return 0
  fi
  bootstrap "$t" --agent claude --mode link > /dev/null 2>&1
  bootstrap "$t" --agent claude --mode copy > /dev/null 2>&1
  local rc=$?
  check "copy mode over an earlier link install exits 0" test "$rc" -eq 0
  check "copy mode replaces links with files" test ! -L "$t/.claude/skills/zz-fixture/SKILL.md"
}

test_single_agent() {
  local t="$TMP/single"
  bootstrap "$t" --agent claude --mode copy > /dev/null 2>&1
  check "AC7 --agent claude installs .claude" test -d "$t/.claude/skills"
  check "AC7 --agent claude creates no other agent dirs" test ! -e "$t/.codex" -a ! -e "$t/.gemini" -a ! -e "$t/.copilot" -a ! -e "$t/.github"
}

outside_markers() {
  awk -v BINMODE=3 '/<!-- .AIAgents Autoload Start -->/ {skip=1} !skip {print} /<!-- .AIAgents Autoload End -->/ {skip=0}' "$1"
}

test_install_sh() {
  local repo="$TMP/srcrepo" t="$TMP/inst"
  mkdir -p "$repo" "$t"
  cp -r "$MOD" "$repo/.AIAgents"
  git -C "$repo" init -q
  git -C "$repo" -c core.autocrlf=false add -A 2> /dev/null
  git -C "$repo" -c core.autocrlf=false -c user.name=smoke -c user.email=smoke@example.invalid commit -q -m fixture
  check "AC4 install.sh defaults to the fork" grep -q 'REPO_URL="https://github.com/lgoda/AIAgentsSmartService.git"' "$SRC_MODULE/../install.sh"
  check "AC4 install.sh --help lists --source and copilot" bash -c "bash '$SRC_MODULE/../install.sh' --help | grep -q -- '--source' && bash '$SRC_MODULE/../install.sh' --help | grep -q copilot"
  bash "$SRC_MODULE/../install.sh" --source "$repo" --agent copilot --target "$t" > "$TMP/inst.log" 2>&1
  local rc=$?
  check "AC4 install.sh --agent copilot --source <clone> exits 0" test "$rc" -eq 0
  check "AC4 copilot files installed" test -d "$t/.copilot/commands" -a -f "$t/.github/skills/zz-fixture/references/ref.md"
  mkdir -p "$TMP/inst-link"
  AIAGENTS_HOME="$TMP/home" bash "$SRC_MODULE/../install.sh" --source "$repo" --agent claude --mode link --target "$TMP/inst-link" > "$TMP/inst-link.log" 2>&1
  rc=$?
  check "install.sh --mode link exits 0" test "$rc" -eq 0
  check "install.sh --mode link: installed files still resolve after install" test -f "$TMP/inst-link/.claude/skills/zz-fixture/references/ref.md"
  check "install.sh --mode link keeps its source clone" test -d "$TMP/home/srcrepo/.git"
}

test_upgrade() {
  local t="$TMP/upgrade"
  bootstrap "$t" --agent all --mode copy > /dev/null 2>&1
  printf 'KEEP-ME\n' >> "$t/.ai/project-context.md"
  mkdir -p "$t/docs" && printf 'mine\n' > "$t/docs/keep.md"
  # simulate an install from an older release: put back a version shipped before the marker existed
  legacy_skill_content > "$t/.claude/skills/data/SKILL.md"
  (cd "$t" && find . -type f | sort) > "$TMP/files-before.txt"
  bootstrap "$t" --agent all --mode copy > /dev/null 2>&1
  (cd "$t" && find . -type f | sort) > "$TMP/files-after.txt"
  check "AC5 project-context.md content preserved" grep -q "KEEP-ME" "$t/.ai/project-context.md"
  check "AC5 no previously installed file deleted" test -z "$(comm -23 "$TMP/files-before.txt" "$TMP/files-after.txt")"
  check "AC5 unrelated project files untouched" test "$(cat "$t/docs/keep.md")" = "mine"
  check "AC5 a skill installed by an older release is upgraded" grep -q "managed-by: aiagents" "$t/.claude/skills/data/SKILL.md"
}

test_startup_files() {
  local t="$TMP/startup" pair file skills
  mkdir -p "$t"
  printf '# My Project\n\nCustom intro.\n' > "$t/CLAUDE.md"
  bootstrap "$t" --agent all --mode copy > /dev/null 2>&1
  printf '\nCustom trailer.\n' >> "$t/CLAUDE.md"
  outside_markers "$t/CLAUDE.md" > "$TMP/outside-before.txt"
  bootstrap "$t" --agent all --mode copy > /dev/null 2>&1
  outside_markers "$t/CLAUDE.md" > "$TMP/outside-after.txt"
  check "AC8 text outside the markers is byte-identical after re-bootstrap" cmp -s "$TMP/outside-before.txt" "$TMP/outside-after.txt"
  check "AC8 custom text outside the markers survives" grep -q "Custom intro" "$t/CLAUDE.md"

  for pair in "CLAUDE.md:.claude/skills" "AGENTS.md:.codex/skills" "GEMINI.md:.gemini/skills" ".github/copilot-instructions.md:.github/skills"; do
    file="$t/${pair%%:*}"
    skills="${pair#*:}"
    check "AC8 $(basename "$file") has exactly one safety block" test "$(grep -c 'Live platform safety' "$file")" -eq 1
    check "AC8 $(basename "$file") lists domain skills" grep -qF "$skills/backend/SKILL.md" "$file"
    check "AC8 $(basename "$file") lists stack skills" grep -qF "$skills/zz-fixture/SKILL.md" "$file"
  done

  sed -n '/Live platform safety/,/Record every live change/p' "$t/CLAUDE.md" > "$TMP/safety-ref.txt"
  for pair in AGENTS.md GEMINI.md .github/copilot-instructions.md; do
    sed -n '/Live platform safety/,/Record every live change/p' "$t/$pair" > "$TMP/safety-cmp.txt"
    check "AC8 safety block identical in $(basename "$pair")" cmp -s "$TMP/safety-ref.txt" "$TMP/safety-cmp.txt"
  done
}

files_missing_automation() {
  # No file may still state the old domain count.
  grep -rlIiE --include='*.md' --include='*.sh' '\b(5|five) (standard )?domains?\b' "$SRC_MODULE" "$SRC_MODULE/../README.md"
  local file
  # Workflow files that must mention the automation domain.
  for file in "$SRC_MODULE"/*/commands/{scan,tasks,implement,fix}.md "$SRC_MODULE"/Claude/skills/{scan,tasks,implement,fix}/SKILL.md; do
    grep -q "automation" "$file" || echo "$file"
  done
  # Any line that enumerates backend and devops together must also name automation.
  grep -rIl --include='*.md' --include='*.sh' -i 'backend.*devops' "$SRC_MODULE"/*/commands "$SRC_MODULE"/*/skills "$SRC_MODULE"/scripts/bootstrap-commands.sh \
    | while read -r file; do
        grep -i 'backend.*devops' "$file" | grep -viE '^(do not load|LEGACY_SKILLS)' | grep -qvi 'automation' && echo "$file"
      done
  # Every agent ships the automation domain skill with the managed marker.

  for file in "$SRC_MODULE"/{Claude,Codex,Gemini,Copilot}/skills/automation/SKILL.md; do
    grep -q 'managed-by: aiagents' "$file" || echo "$file"
  done
}

test_domain_consistency() {
  local missing
  missing="$(files_missing_automation | sort -u)"
  check "domains: every enumeration and workflow file names automation" test -z "$missing"
  [[ -z "$missing" ]] || echo "$missing" | sed 's/^/        missing: /'
}

write_lint_fixture() {
  local dir="$1"
  rm -rf "$dir" && mkdir -p "$dir/good/references"
  printf -- '---\nname: good\ndescription: A good skill. Use when testing.\nmetadata:\n  managed-by: aiagents\n---\n\n# good\n\n## Hard rules\n- a\n\n## Workflow\n1. a\n\n## Verification\n- a\n\n## Failure modes\n- a\n\n## References\n| task | file |\n' > "$dir/good/SKILL.md"
  printf '# ref\nLast verified: 2026-01-01\n' > "$dir/good/references/ref.md"
}

lint_rejects() {
  local desc="$1" mutate="$2" dir="$TMP/lint"
  write_lint_fixture "$dir"
  printf 'acmecorp\n' > "$TMP/lint-deny.txt"
  eval "$mutate"
  check "lint rejects: $desc" bash -c "! bash '$MOD/scripts/lint-skills.sh' '$dir' '$TMP/lint-deny.txt'"
}

test_lint_script() {
  local dir="$TMP/lint" f
  write_lint_fixture "$dir"
  printf 'acmecorp\n' > "$TMP/lint-deny.txt"
  check "lint accepts a good skill" bash "$MOD/scripts/lint-skills.sh" "$dir" "$TMP/lint-deny.txt"
  f="$dir/good/SKILL.md"
  lint_rejects "name differs from directory" "edit_in_place 's/^name: good/name: other/' $dir/good/SKILL.md"
  lint_rejects "missing description" "edit_in_place '/^description:/d' $dir/good/SKILL.md"
  lint_rejects "missing managed marker" "edit_in_place '/managed-by/d' $dir/good/SKILL.md"
  lint_rejects "SKILL.md over 600 words" "yes word | head -700 >> $dir/good/SKILL.md"
  lint_rejects "missing Verification section" "edit_in_place '/^## Verification/d' $dir/good/SKILL.md"
  lint_rejects "reference without Last verified" "printf '# ref\n' > $dir/good/references/ref.md"
  lint_rejects "reference over 1800 words" "yes word | head -1900 >> $dir/good/references/ref.md"
  lint_rejects "denylist match" "printf 'Built for AcmeCorp\n' >> $dir/good/SKILL.md"
  lint_rejects "agent-specific tool name" "printf 'Use TodoWrite here\n' >> $dir/good/SKILL.md"
}

DOMAIN_SKILLS="backend frontend data testing devops automation"
STACK_SKILLS="integrations n8n voice-agents messaging crm conversational-agents mcp-servers"

# Real shipped skills: every agent gets 6 domain + 7 stack skills, listed in its startup file.
test_real_skill_set() {
  local t="$TMP/real" pair dir name file
  bootstrap "$t" --agent all --mode copy > /dev/null 2>&1
  for pair in $AGENT_DIRS; do
    dir="$t/${pair#*:}"
    for name in $DOMAIN_SKILLS $STACK_SKILLS; do
      check "AC1 ${pair#*:} has $name" test -f "$dir/$name/SKILL.md"
    done
  done
  for name in $STACK_SKILLS; do
    check "AC2 $name identical in all agents (with references)" shared_installed_everywhere "$t" "$name"
  done
  for pair in "CLAUDE.md:.claude/skills" "AGENTS.md:.codex/skills" "GEMINI.md:.gemini/skills" ".github/copilot-instructions.md:.github/skills"; do
    file="$t/${pair%%:*}"
    check "AC8 $(basename "$file") lists all 13 skills" bash -c "for n in $DOMAIN_SKILLS $STACK_SKILLS; do grep -qF '${pair#*:}/'\$n'/SKILL.md' '$file' || exit 1; done"
  done
}

test_crlf_startup_file() {
  local t="$TMP/crlf"
  mkdir -p "$t"
  printf '# My Project\r\n\r\nCustom intro.\r\n' > "$t/CLAUDE.md"
  bootstrap "$t" --agent claude --mode copy > /dev/null 2>&1
  printf 'Custom trailer.\r\n' >> "$t/CLAUDE.md"
  outside_markers "$t/CLAUDE.md" > "$TMP/crlf-before.txt"
  bootstrap "$t" --agent claude --mode copy > /dev/null 2>&1
  outside_markers "$t/CLAUDE.md" > "$TMP/crlf-after.txt"
  check "AC8 CRLF text outside the markers is preserved byte for byte" cmp -s "$TMP/crlf-before.txt" "$TMP/crlf-after.txt"
  check "AC8 CRLF endings are still present" test "$(awk -v BINMODE=3 '/\r$/ {n++} END {print n+0}' "$t/CLAUDE.md")" -ge 4
  check "AC8 re-bootstrap keeps exactly one autoload block" test "$(grep -c 'Autoload Start' "$t/CLAUDE.md")" -eq 1
}

test_link_fallback() {
  local t="$TMP/linkfail" shim="$TMP/shim"
  mkdir -p "$shim"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$shim/ln" && chmod +x "$shim/ln"
  PATH="$shim:$PATH" bootstrap "$t" --agent claude --mode link > "$TMP/linkfail.log" 2>&1
  local rc=$?
  check "AC3 link mode with failing ln exits 0" test "$rc" -eq 0
  check "AC3 link mode with failing ln still installs the files" test -f "$t/.claude/skills/zz-fixture/references/ref.md" -a -f "$t/.claude/skills/backend/SKILL.md"
  check "AC3 link mode with failing ln warns exactly once" test "$(grep -c 'symlinks are not supported' "$TMP/linkfail.log")" -eq 1
}

setup_module
test_domain_consistency
test_lint_script
test_real_skill_set
test_crlf_startup_file
test_link_fallback
test_copy_install
test_override
test_link_mode
test_collision_guard
test_link_then_copy
test_single_agent
test_install_sh
test_upgrade
test_startup_files

if [[ "$FAILED" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "$FAILED check(s) failed."
  exit 1
fi
