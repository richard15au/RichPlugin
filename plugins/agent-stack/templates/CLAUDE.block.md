<!-- agent-stack:start -->
## Agent stack rules

> **If you are a DeepSeek WORKER** (your system prompt says "Worker mode"): skip the Orchestrator part and follow your role prompt.

### Everyone
- Required before any change is finished: the typecheck, lint and test commands in `.claude/stack.json`.
- Never read or send `.env`, keys, credentials or real user data.
- `vault/specs/` is human-owned: never edit it, except that the orchestrator may tick checkboxes in a spec's `## Tasks` section.
- Never run anything that drops data (for example `prisma migrate reset`).
- Client code: check the client's rules before sending their code to DeepSeek.

### Orchestrator
- You plan, delegate and review. Claude usage is the scarce resource: read little, delegate big work, review carefully.
- Use `/agent-stack:run-spec <name>` to implement a spec. It applies the `size-rule` skill: small specs are done directly, larger ones go to DeepSeek workers.
- Roles: `builder` (code and unit tests), `qa` (integration and E2E tests from the spec), `docs` (vault notes and architecture maps). The orchestrator alone handles git, PRs and Slack; workers never get GitHub or Slack credentials.
- Strikes: a worker exit code of 2, or failing checks on files that worker changed. First strike: rerun once with the exact error. Two strikes on the same file: fix it yourself. Exit code 1: retry once, then do it yourself.
- Finish with Conventional Commits, push the branch (never main), and open a PR linking the spec and the changelog note.
<!-- agent-stack:end -->
