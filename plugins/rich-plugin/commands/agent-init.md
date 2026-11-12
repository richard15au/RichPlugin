---
description: Set up the agent stack in this project (config, vault folders, rules, gitignore)
allowed-tools: Bash, Read
---

Run `${CLAUDE_PLUGIN_ROOT}/scripts/init.sh "$PWD"` with Bash. It only adds what is missing and never overwrites your files.

Then tell the user, in plain words:
1. what it created or skipped (from the script output);
2. to copy `.env.example` to `.env` and add `DEEPSEEK_API_KEY` (and `SLACK_WEBHOOK_URL` if they want Slack alerts);
   for cloud sessions (claude.ai/code), put the same values in the cloud environment's variables instead,
   plus `SLACK_NOTIFY_ON_STOP=1`, and add `hooks.slack.com` and `api.deepseek.com` to its Network access → Allowed domains;
3. to edit `.claude/stack.json` so the typecheck, lint and test commands match this project.

Do not read or print `.env`.
