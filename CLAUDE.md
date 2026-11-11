# Project rules

> **If you are a DeepSeek WORKER** (your system prompt says "Worker mode"): skip every section marked
> *Orchestrator* below. Use only the Shared rules and your worker instructions.

## Shared rules (everyone)
- Skills in `.claude/skills/` are the house rules: `stack-rules`, `minimal-code`, `ui-design`, `obsidian-docs`.
- Required before any change is finished: `npm run typecheck`, `npm run lint`, tests for touched code.
- Never read or send `.env`, keys, credentials, or real student/user data.
- Never edit `vault/specs/` (human-owned). Never run `prisma migrate reset` or anything that drops data.

## Orchestrator — role
You plan, delegate and review. DeepSeek workers run inside Claude Code with the same tools and skills
as you, but on the DeepSeek API. Your quota is the scarce resource: read little, delegate the writing, review carefully.

## Orchestrator — start of session
1. Run `/caveman full`. It applies to your chat replies ONLY — never to commits, PR text, vault notes, or worker tasks.
2. Read the spec named in the request: `vault/specs/<name>.md`. Open `vault/architecture/` notes only if the spec links them.
3. Split it into subtasks. Each has: a goal, the likely files, which skills apply, and an acceptance check.

## Orchestrator — delegating
Default (DeepSeek as a full Claude Code agent):
```
.claude/scripts/deepseek_agent.sh "Goal: ... Files: ... Acceptance: ... Skills: stack-rules, minimal-code"
```
- Write tasks in clear, full English (no caveman). Name files and the acceptance check; don't paste file contents.
- Long tasks: write to `.claude/logs/task-<n>.md`, pass `@.claude/logs/task-<n>.md`.
- **Parallel:** give each worker its own worktree, in one Bash call:
  `.claude/scripts/deepseek_agent.sh --worktree a "..." & .claude/scripts/deepseek_agent.sh --worktree b "..." & wait`
  Then for each: `git diff HEAD...worker/<name>` → review → `git merge --squash worker/<name>` →
  `git worktree remove .worktrees/<name> && git branch -D worker/<name>`.
  Only parallelise subtasks that touch different files.
- Without `--worktree`, changes land uncommitted in the main tree — review with `git diff`.
- Backup for a tiny one-file edit, or if the agent runner fails:
  `python3 .claude/scripts/deepseek_worker.py --task "..." --edit <files> --read <files> --skill minimal-code,stack-rules`
- Don't open `.claude/logs/` unless debugging a failure.

## Orchestrator — reviewing
- Run commands normally; the RTK hook compresses their output. To inspect a file prefer `rtk read <file>` (the Read tool bypasses RTK).
- Order: `git diff --stat` → `git diff <file>` → typecheck/lint/tests → `/ponytail-review`.

## Orchestrator — escalation (strikes)
- A strike = runner exit 2 (FAIL/BLOCKED) OR checks fail on files that worker changed.
- First strike: rerun once, putting the exact error in the task.
- **2 strikes on the same file → stop delegating that file and fix it yourself.**
- Exit 1 (setup/API error): retry once, then do it yourself and note it in the PR.

## Orchestrator — finishing
1. Delegate the changelog: `deepseek_agent.sh "Write vault/changelog/<YYYY-MM-DD>-<slug>.md for this change using the obsidian-docs skill. Spec: vault/specs/<name>.md. Summary of the diff: ..."`
   One new note per task — never append to a shared changelog.
2. Commit in normal English (Conventional Commits), push the branch, open a PR linking the spec and the changelog note.
