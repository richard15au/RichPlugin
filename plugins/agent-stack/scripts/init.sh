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

# Slack notifier: copy into the project so cloud sessions run it even when the plugin isn't loaded.
copy_if_missing "$PLUGIN/scripts/notify.sh" .claude/scripts/notify.sh
chmod +x .claude/scripts/notify.sh

# settings.json: merge in the runner permission and the Slack hooks. Adds only; never removes your settings.
SETTINGS=.claude/settings.json
python3 -I - "$SETTINGS" <<'PY'
import json, os, sys
path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    try:
        cfg = json.load(open(path))
    except ValueError:
        print(f"skip    {path} (not valid JSON; fix it and run again)")
        sys.exit(0)
changed = []
allow = cfg.setdefault("permissions", {}).setdefault("allow", [])
if not any("deepseek_agent.sh" in a for a in allow):
    allow.append("Bash(*deepseek_agent.sh:*)"); changed.append("runner permission")
cmd = 'bash "$CLAUDE_PROJECT_DIR/.claude/scripts/notify.sh"'
hooks = cfg.setdefault("hooks", {})
for ev in ("Notification", "Stop"):
    groups = hooks.setdefault(ev, [])
    if not any("notify.sh" in h.get("command", "") for g in groups for h in g.get("hooks", [])):
        groups.append({"hooks": [{"type": "command", "command": cmd}]}); changed.append(f"{ev} Slack hook")
if changed:
    existed = os.path.exists(path)
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2); f.write("\n")
    print(("updated " if existed else "created ") + path + " (" + ", ".join(changed) + ")")
else:
    print(f"skip    {path} (already set up)")
PY
echo "done"
