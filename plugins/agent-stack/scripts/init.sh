#!/usr/bin/env bash
# Add the agent stack to a project. Only adds what is missing; never overwrites.
# Usage: init.sh [project-dir]
set -euo pipefail
PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
T="$PLUGIN/templates"
DIR="${1:-$PWD}"
cd "$DIR"
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "FAIL not a git repository: $DIR"; exit 1; }
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

copy_if_missing() {  # copy_if_missing <template> <destination>
  if [[ -e "$2" ]]; then echo "skip    $2 (exists)"; else mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "created $2"; fi
}

copy_if_missing "$T/stack.json" .claude/stack.json
copy_if_missing "$T/spec-template.md" vault/specs/_template.md
copy_if_missing "$T/goal-template.md" vault/goals/_template.md
copy_if_missing "$T/env.example" .env.example
mkdir -p vault/changelog vault/architecture

# CLAUDE.md: add our block once, between markers, keeping the user's own text.
if [[ ! -f CLAUDE.md ]]; then
  { echo "# Project rules"; echo; cat "$T/CLAUDE.block.md"; } > CLAUDE.md; echo "created CLAUDE.md"
elif ! grep -q 'agent-stack:start' CLAUDE.md; then
  { echo; cat "$T/CLAUDE.block.md"; } >> CLAUDE.md; echo "updated CLAUDE.md (added agent-stack block)"
else
  echo "skip    CLAUDE.md (block already present)"
fi

# .gitignore: add our block once.
touch .gitignore
if grep -q 'agent-stack ---' .gitignore; then
  echo "skip    .gitignore (block already present)"
else
  { echo; cat "$T/gitignore.add"; } >> .gitignore; echo "updated .gitignore"
fi

# Let the orchestrator run the runner without a prompt each time.
SETTINGS=.claude/settings.json
if [[ ! -f "$SETTINGS" ]]; then
  printf '{\n  "permissions": {\n    "allow": ["Bash(*deepseek_agent.sh:*)"]\n  }\n}\n' > "$SETTINGS"
  echo "created $SETTINGS"
else
  echo "skip    $SETTINGS (exists; add \"Bash(*deepseek_agent.sh:*)\" to permissions.allow yourself if you want no prompts)"
fi
echo "done"
