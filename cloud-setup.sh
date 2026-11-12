#!/usr/bin/env bash
# One-click cloud setup for claude.ai/code. Paste this into the environment's setup script field:
#   curl -fsSL https://raw.githubusercontent.com/richard15au/RichPlugin/main/cloud-setup.sh | bash
# Runs as root before each fresh session. Installs rich-plugin into every cloned repo, plus what the workers need.
# Needs the environment's network to allow: github.com, raw.githubusercontent.com (and api.deepseek.com, hooks.slack.com at run time).
# Never fails the session: problems are printed as warnings.
set -uo pipefail
RAW="https://raw.githubusercontent.com/richard15au/RichPlugin/main/install.sh"

# DeepSeek workers run inside the Claude Code CLI (headless).
command -v claude >/dev/null || npm install -g @anthropic-ai/claude-code || echo "WARN could not install the claude CLI"

for d in */; do
  [[ -d "$d/.git" ]] || continue
  echo "== $d"
  ( cd "$d" \
    && { curl -fsSL "$RAW" | bash; } \
    && { [[ ! -f package.json ]] || npm ci --no-audit --no-fund; } ) || echo "WARN setup failed in $d"
done

cat <<'MSG'
Set these in the cloud environment (variables, not in git):
  DEEPSEEK_API_KEY        required for workers
  SLACK_WEBHOOK_URL       optional Slack alerts
  SLACK_NOTIFY_ON_STOP=1  optional, message after every turn
Network allowlist: api.deepseek.com, hooks.slack.com
MSG
