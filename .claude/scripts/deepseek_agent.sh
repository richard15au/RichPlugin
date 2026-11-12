#!/usr/bin/env bash
# Run ONE subtask with DeepSeek inside Claude Code: same tools, skills and working loop as Claude,
# but billed to your DeepSeek API key instead of your Claude plan.
#
# Usage:
#   .claude/scripts/deepseek_agent.sh [--worktree NAME] [--max-turns N] "task text"   (or @path/to/task.md)
#
# --worktree NAME  run in .worktrees/NAME on branch worker/NAME (use for parallel workers);
#                  the result is committed there so the orchestrator can review and merge it.
# Prints one line: OK|FAIL turns=.. tokens=in/out | SUMMARY..., then a diffstat.
# Exit: 0 ok, 1 setup/API error, 2 worker failed or BLOCKED (counts as a strike).
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
WT="" TURNS=40
while [[ $# -gt 1 ]]; do
  case "$1" in
    --worktree) WT="$2"; shift 2 ;;
    --max-turns) TURNS="$2"; shift 2 ;;
    *) break ;;
  esac
done
TASK="${1:?usage: deepseek_agent.sh [--worktree NAME] [--max-turns N] \"task\"}"
[[ "$TASK" == @* ]] && TASK="$(cat "$ROOT/${TASK#@}")"
[[ -n "${DEEPSEEK_API_KEY:-}" ]] || { echo "FAIL DEEPSEEK_API_KEY not set"; exit 1; }

DIR="$ROOT"
if [[ -n "$WT" ]]; then
  DIR="$ROOT/.worktrees/$WT"
  git -C "$ROOT" worktree add -q -b "worker/$WT" "$DIR" HEAD
  # Share installed dependencies so checks run in the worktree (never committed, see add below).
  [[ -d "$ROOT/node_modules" ]] && ln -s "$ROOT/node_modules" "$DIR/node_modules"
fi

MODEL="${DEEPSEEK_MODEL:-deepseek-flash}"
mkdir -p "$ROOT/.claude/logs"
LOG="$ROOT/.claude/logs/agent-$(date +%Y%m%d-%H%M%S)-${WT:-main}-$$.json"

# Strip every Anthropic credential so your Claude login is never sent to DeepSeek,
# and use a separate config dir so the worker can't touch the orchestrator's session.
cd "$DIR"
set +e
env -u CLAUDE_CODE_OAUTH_TOKEN -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_BASE_URL \
  ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY" \
  ANTHROPIC_API_KEY="$DEEPSEEK_API_KEY" \
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
    --settings "$ROOT/.claude/worker-settings.json" \
    --append-system-prompt "$(cat "$ROOT/.claude/worker/core.md" "$ROOT/.claude/worker/agent.md")" \
    --permission-mode acceptEdits \
    --allowedTools "Read" "Edit" "Write" "Glob" "Grep" "Skill" "TodoWrite" \
      "Bash(npm run typecheck)" "Bash(npm run lint:*)" "Bash(npm run test:*)" "Bash(npm test:*)" \
      "Bash(npx vitest:*)" "Bash(npx tsc:*)" "Bash(npx prisma validate)" "Bash(npx prisma format)" \
      "Bash(npx prisma generate)" "Bash(git status:*)" "Bash(git diff:*)" "Bash(ls:*)" \
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
  git -C "$DIR" add -A -- . ":!node_modules"
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
