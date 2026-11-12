#!/usr/bin/env bash
# Install rich-plugin into the current git project's .claude/ folder (works locally and in cloud sessions).
# Usage: curl -fsSL https://raw.githubusercontent.com/richard15au/RichPlugin/main/install.sh | bash
# Re-run to update. Env: RICHPLUGIN_SRC overrides the repo URL/path (for testing).
set -euo pipefail

SRC="${RICHPLUGIN_SRC:-https://github.com/richard15au/RichPlugin.git}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "FAIL not inside a git repository"; exit 1; }
command -v python3 >/dev/null || { echo "FAIL python3 is required"; exit 1; }
cd "$ROOT"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "download $SRC"
git -c core.autocrlf=false -c core.eol=lf clone --quiet --depth 1 --branch main "$SRC" "$TMP/src" 2>/dev/null \
  || git -c core.autocrlf=false -c core.eol=lf clone --quiet --depth 1 "$SRC" "$TMP/src"
P="$TMP/src/plugins/rich-plugin"
[[ -d "$P" ]] || { echo "FAIL plugins/rich-plugin not found in $SRC"; exit 1; }
find "$P" -type f \( -name '*.sh' -o -name '*.md' -o -name '*.json' -o -name '*.py' -o -name '*.add' \) -exec sed -i 's/\r$//' {} +

add_if_missing() {  # add_if_missing <src> <dest>
  if [[ -e "$2" ]]; then echo "skip    $2 (exists)"; else mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "created $2"; fi
}

# 2. Plugin files (replaced)
rm -rf .claude/rich-plugin
mkdir -p .claude/rich-plugin
for d in scripts roles skills templates; do cp -R "$P/$d" .claude/rich-plugin/; done
cp "$P/worker-settings.json" .claude/rich-plugin/
chmod +x .claude/rich-plugin/scripts/*.sh
echo "updated .claude/rich-plugin/"

# 3. Commands (replaced, paths rewritten)
mkdir -p .claude/commands
for c in agent-init run-spec; do
  sed -e 's#\${CLAUDE_PLUGIN_ROOT}#.claude/rich-plugin#g' -e 's#/rich-plugin:#/#g' "$P/commands/$c.md" > ".claude/commands/$c.md"
done
echo "updated .claude/commands/{agent-init,run-spec}.md"

# 4. Skills (only if missing)
for s in minimal-code obsidian-docs size-rule ui-design; do
  [[ -d ".claude/skills/$s" ]] && echo "skip    .claude/skills/$s (exists)" \
    || { mkdir -p .claude/skills; cp -R "$P/skills/$s" ".claude/skills/$s"; echo "created .claude/skills/$s"; }
done

# 5. Project setup (only if missing)
T="$P/templates"
add_if_missing "$T/stack.json" .claude/stack.json
add_if_missing "$T/spec-template.md" vault/specs/_template.md
add_if_missing "$T/goal-template.md" vault/goals/_template.md
add_if_missing "$T/env.example" .env.example
mkdir -p vault/changelog vault/architecture

# 6. CLAUDE.md (block appended once)
BLOCK="$(sed 's#/rich-plugin:#/#g' "$T/CLAUDE.block.md")"
if [[ ! -f CLAUDE.md ]]; then
  printf '# Project rules\n\n%s\n' "$BLOCK" > CLAUDE.md; echo "created CLAUDE.md"
elif ! grep -q 'rich-plugin:start' CLAUDE.md; then
  printf '\n%s\n' "$BLOCK" >> CLAUDE.md; echo "updated CLAUDE.md (added rich-plugin block)"
else echo "skip    CLAUDE.md (block already present)"; fi

# 7. .gitignore
touch .gitignore
if grep -q 'rich-plugin ---' .gitignore; then echo "skip    .gitignore (block already present)"
else { echo; cat "$T/gitignore.add"; } >> .gitignore; echo "updated .gitignore"; fi

# 8. Slack notifier (replaced)
mkdir -p .claude/scripts
cp "$P/scripts/notify.sh" .claude/scripts/notify.sh; chmod +x .claude/scripts/notify.sh
echo "updated .claude/scripts/notify.sh"

# 9. settings.json (merge)
python3 -I - .claude/settings.json <<'PY'
import json, os, sys
path = sys.argv[1]
cfg = {}
if os.path.exists(path):
    try: cfg = json.load(open(path))
    except ValueError:
        print(f"skip    {path} (not valid JSON; fix it and run again)"); sys.exit(0)
changed = []
allow = cfg.setdefault("permissions", {}).setdefault("allow", [])
if not any("deepseek_agent.sh" in a for a in allow):
    allow.append("Bash(*deepseek_agent.sh:*)"); changed.append("runner permission")
cmd = 'bash "$CLAUDE_PROJECT_DIR/.claude/scripts/notify.sh"'
hooks = cfg.setdefault("hooks", {})
for ev in ("Notification", "Stop"):
    groups = hooks.setdefault(ev, [])
    if not any("notify.sh" in h.get("command", "") for g in groups for h in g.get("hooks", [])):
        groups.append({"hooks": [{"type": "command", "command": cmd}]}); changed.append(f"{ev} hook")
m = cfg.get("extraKnownMarketplaces", {})
if "richard-stack" in m:
    del m["richard-stack"]; changed.append("removed richard-stack marketplace")
    if not m: del cfg["extraKnownMarketplaces"]
e = cfg.get("enabledPlugins", {})
if "rich-plugin@richard-stack" in e:
    del e["rich-plugin@richard-stack"]; changed.append("removed rich-plugin@richard-stack")
    if not e: del cfg["enabledPlugins"]
if changed:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f: json.dump(cfg, f, indent=2); f.write("\n")
    print("updated " + path + " (" + ", ".join(changed) + ")")
else: print(f"skip    {path} (already set up)")
PY

# 10. .gitattributes
touch .gitattributes
if grep -qxF '*.sh text eol=lf' .gitattributes; then echo "skip    .gitattributes (already set)"
else echo '*.sh text eol=lf' >> .gitattributes; echo "updated .gitattributes"; fi

echo "done. Check .claude/stack.json, then: git add -A && git commit -m 'chore: install rich-plugin' && git push"
