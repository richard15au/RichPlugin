#!/usr/bin/env bash
# Optional Slack alert for Claude Code hooks (Notification always; Stop only if SLACK_NOTIFY_ON_STOP=1).
# Needs SLACK_WEBHOOK_URL in the environment or in the project's git-ignored .env. Silent no-op without it.
# Never runs for DeepSeek workers, and never prints the webhook URL.
[[ "${DEEPSEEK_WORKER:-}" == "1" ]] && exit 0
INPUT="$(cat)"
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
# If the project has its own copy (added by agent-init), let that one send, so there are no duplicates.
LOCAL="$ROOT/.claude/scripts/notify.sh"
[[ -f "$LOCAL" && "$(realpath "$LOCAL")" != "$(realpath "${BASH_SOURCE[0]}")" ]] && exit 0
URL="${SLACK_WEBHOOK_URL:-}"
if [[ -z "$URL" && -f "$ROOT/.env" ]]; then
  URL="$(grep -E '^SLACK_WEBHOOK_URL=' "$ROOT/.env" | head -1 | cut -d= -f2- | tr -d "\"'")"
fi
[[ -n "$URL" ]] || exit 0
STOP_FLAG="${SLACK_NOTIFY_ON_STOP:-}"
[[ -z "$STOP_FLAG" && -f "$ROOT/.env" ]] && STOP_FLAG="$(grep -E '^SLACK_NOTIFY_ON_STOP=' "$ROOT/.env" | head -1 | cut -d= -f2-)"

PAYLOAD="$(python3 -I - "$INPUT" "$ROOT" "$STOP_FLAG" <<'EOF'
import json, os, sys
try:
    d = json.loads(sys.argv[1] or "{}")
except ValueError:
    d = {}
ev = d.get("hook_event_name", "")
if ev == "Stop" and sys.argv[3] != "1":
    sys.exit(3)
project = os.path.basename(sys.argv[2])
if ev == "Notification":
    msg = d.get("message", "Claude is waiting")
    text = ":bell: *" + project + "* needs you: " + msg
else:
    text = ":white_check_mark: *" + project + "*: Claude finished a turn"
print(json.dumps({"text": text}))
EOF
)" || exit 0
curl -fsS -m 10 -X POST -H 'Content-Type: application/json' --data "$PAYLOAD" "$URL" >/dev/null 2>&1 || true
exit 0
