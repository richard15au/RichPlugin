# agent-stack

A Claude Code plugin: Claude plans, delegates and reviews; DeepSeek workers write the code, tests and notes (billed to your DeepSeek key). Built to save Claude usage on bigger jobs.

## Install
```
/plugin marketplace add richard15au/Claude-test
/plugin install agent-stack@richard-stack
```
Then, in any project (a git repo): `/agent-stack:agent-init`. Copy `.env.example` to `.env`, add `DEEPSEEK_API_KEY`, and edit `.claude/stack.json` so the commands fit the project.

## Use
- Write a spec in `vault/specs/<name>.md` (copy `_template.md`), then run `/agent-stack:run-spec <name>`.
- The `size-rule` skill decides per spec: small jobs are done by Claude directly, bigger ones go to workers.
- Roles: `builder` (code and unit tests), `qa` (integration/E2E tests from the spec), `docs` (vault notes, architecture maps). Run one by hand with `deepseek_agent.sh --role qa "task"`.
- Parallel workers: add `--worktree NAME`, one per subtask that touches different files.

## Safety
- Workers get only the DeepSeek key. Claude, GitHub and Slack credentials are stripped from their environment.
- Workers cannot push, commit (outside their own worktree), reset, delete files, run migrations or use the web, and cannot read `.env`, keys or edit `vault/specs/`, `.claude/` or `CLAUDE.md`.
- Git, PRs and Slack stay with the orchestrator. Never commit `.env`; `/agent-stack:agent-init` adds the ignore rules.
- Set a spending cap or alert on your DeepSeek account. Check a client's rules before sending their code to DeepSeek.

## Slack (optional)
Put an incoming-webhook URL in `.env` as `SLACK_WEBHOOK_URL`. You get a message whenever Claude is waiting for you; add `SLACK_NOTIFY_ON_STOP=1` for a message after every turn. `agent-init` copies the notifier to `.claude/scripts/notify.sh` and adds the hooks to `.claude/settings.json`, so it also works in cloud sessions where the plugin isn't loaded. In the cloud, set the variables in the environment and allow `hooks.slack.com` under Network access. For PR visibility, use the GitHub app for Slack: `/github subscribe owner/repo reviews comments workflows`.

## Known limits
- The size-rule thresholds are provisional. Test 8 only showed a tie on a 3-check spec; a bigger spec is still to be measured.
- The plugin does not install RTK, Caveman or Ponytail; use them separately if you want them.
- Run `npm audit` findings through Dependabot, not `npm audit fix --force`.
