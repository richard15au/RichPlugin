#!/usr/bin/env bash
# Run ONE subtask with DeepSeek inside Claude Code: same tools and skills as Claude, billed to your DeepSeek key.
#
# Usage:
#   deepseek_agent.sh [--role builder|qa|docs] [--worktree NAME] [--max-turns N] "task text"   (or @path/to/task.md)
#
# --role      which role prompt to add (default builder); see roles/ in the plugin.
# --worktree  run in .worktrees/NAME on branch worker/NAME (for parallel workers); the result is committed there.
# Project settings come from .claude/stack.json (commands, model); see templates/stack.json.
# Prints one line: OK|FAIL turns=.. tokens=in/out | SUMMARY..., then a diffstat.
# Exit: 0 ok, 1 setup/API error, 2 worker failed or BLOCKED (counts as a strike).
set -euo pipefail

PLUGIN="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ROOT="$(git rev-parse --show-toplevel)"
CONFIG="$ROOT/.claude/stack.json"
WT="" TURNS=40 ROLE=builder
while [[ $# -gt 1 ]]; do
  case "$1" in
    --worktree) WT="$2"; shift 2 ;;
    --max-turns) TURNS="$2"; shift 2 ;;
    --role) ROLE="$2"; shift 2 ;;
    *) break ;;
  esac
done
TASK="${1:?usage: deepseek_agent.sh [--role R] [--worktree NAME] [--max-turns N] \"task\"}"
[[ "$TASK" == @* ]] && TASK="$(cat "$ROOT/${TASK#@}")"
[[ -f "$PLUGIN/roles/$ROLE.md" ]] || { echo "FAIL unknown role: $ROLE"; exit 1; }

# Read only the two DeepSeek settings from the git-ignored .env (never source it: it may hold other secrets).
envval() { [[ -f "$ROOT/.env" ]] && grep -E "^$1=" "$ROOT/.env" | head -1 | cut -d= -f2- | tr -d "\"'" || true; }
KEY="${DEEPSEEK_API_KEY:-$(envval DEEPSEEK_API_KEY)}"
[[ -n "$KEY" ]] || { echo "FAIL DEEPSEEK_API_KEY not set"; exit 1; }
CFG_MODEL="$(python3 -I -c 'import json,sys; print(json.load(open(sys.argv[1])).get("model",""))' "$CONFIG" 2>/dev/null || true)"
MODEL="${DEEPSEEK_MODEL:-$(envval DEEPSEEK_MODEL)}"
MODEL="${MODEL:-${CFG_MODEL:-deepseek-flash}}"

# Tool allow-list: fixed safe tools plus the project's own commands from stack.json.
mapfile -t ALLOWED < <(python3 -I - "$CONFIG" <<'EOF'
import json, os, sys
cfg = json.load(open(sys.argv[1])) if os.path.exists(sys.argv[1]) else {}
cmds = cfg.get("commands") or {"typecheck": "npm run typecheck", "lint": "npm run lint", "test": "npm test"}
out = ["Read", "Edit", "Write", "Glob", "Grep", "Skill", "TodoWrite",
       "Bash(git status:*)", "Bash(git diff:*)", "Bash(ls:*)"]
for c in list(cmds.values()) + list(cfg.get("extra_allowed") or []):
    out += [f"Bash({c})", f"Bash({c}:*)"]
print("\n".join(out))
EOF
)

DIR="$ROOT"
if [[ -n "$WT" ]]; then
  DIR="$ROOT/.worktrees/$WT"
  git -C "$ROOT" worktree add -q -b "worker/$WT" "$DIR" HEAD
  # Share installed dependencies so checks run in the worktree (never committed, see add below).
  [[ -d "$ROOT/node_modules" ]] && ln -s "$ROOT/node_modules" "$DIR/node_modules"
fi

PROMPT="$(cat "$PLUGIN/roles/core.md" "$PLUGIN/roles/$ROLE.md")"
[[ -f "$ROOT/.claude/worker/extra.md" ]] && PROMPT="$PROMPT"$'\n\n'"$(cat "$ROOT/.claude/worker/extra.md")"

mkdir -p "$ROOT/.claude/logs"
LOG="$ROOT/.claude/logs/agent-$(date +%Y%m%d-%H%M%S)-${WT:-main}-$$.json"

# Strip every credential the worker must not have (Claude login, GitHub, Slack) and use a separate
# config dir so the worker can't touch the orchestrator's session.
cd "$DIR"
set +e
env -u CLAUDE_CODE_OAUTH_TOKEN -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL \
  -u GITHUB_TOKEN -u GH_TOKEN -u SLACK_WEBHOOK_URL -u SLACK_BOT_TOKEN \
  ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$KEY" \
  ANTHROPIC_API_KEY="$KEY" \
  ANTHROPIC_MODEL="$MODEL" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$MODEL" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$MODEL" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$MODEL" \
  CLAUDE_CODE_SUBAGENT_MODEL="$MODEL" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 \
  CLAUDE_CONFIG_DIR="$HOME/.claude-deepseek-worker" \
  DEEPSEEK_WORKER=1 \
  claude -p "$TASK" \
    --output-format json \
    --max-turns "$TURNS" \
    --plugin-dir "$PLUGIN" \
    --settings "$PLUGIN/worker-settings.json" \
    --append-system-prompt "$PROMPT" \
    --permission-mode acceptEdits \
    --allowedTools "${ALLOWED[@]}" \
    --disallowedTools "WebFetch" "WebSearch" "Bash(git push:*)" "Bash(git commit:*)" "Bash(git reset:*)" \
      "Bash(npx prisma migrate:*)" "Bash(rm:*)" \
    > "$LOG" 2>"$LOG.err"
CLAUDE_EXIT=$?
set -e

if [[ ! -s "$LOG" ]]; then
  echo "FAIL claude exited $CLAUDE_EXIT with no output (see ${LOG#"$ROOT"/}.err)"
  exit 1
fi

set +e
python3 -I - "$LOG" <<'EOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except ValueError:
    print("FAIL unreadable worker output"); sys.exit(1)
lines = (d.get("result") or "").strip().splitlines()
summary = next((l for l in reversed(lines) if l.startswith("SUMMARY:")), None)
missing = summary is None
if missing:  # worker ignored the output contract -> treat as a failure so the orchestrator notices
    summary = "SUMMARY: NO-SUMMARY " + (lines[-1][:150] if lines else "(empty reply)")
u = d.get("usage") or {}
bad = missing or d.get("is_error") or "BLOCKED" in summary or d.get("subtype") == "error_max_turns"
print(f"{'FAIL' if bad else 'OK'} turns={d.get('num_turns')} tokens={u.get('input_tokens', '?')}/{u.get('output_tokens', '?')} | {summary[len('SUMMARY:'):].strip()}")
sys.exit(2 if bad else 0)
EOF
RESULT=$?
set -e

if [[ -n "$WT" ]]; then
  git -C "$DIR" add -A
  git -C "$DIR" rm -q --cached --ignore-unmatch node_modules >/dev/null  # never commit the shared link
  git -C "$DIR" diff --cached --stat | tail -n 1
  if ! git -C "$DIR" diff --cached --quiet; then
    git -C "$DIR" -c user.name="deepseek-worker" -c user.email="worker@localhost" commit -qm "worker($WT): ${TASK:0:60}"
  fi
  echo "branch=worker/$WT"
else
  # Leave changes uncommitted in the main tree for the orchestrator to review.
  git -C "$DIR" status --short | awk 'END {print NR " files changed/new"}'
fi
exit $RESULT
