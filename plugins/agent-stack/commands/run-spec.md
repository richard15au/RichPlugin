---
description: Implement a spec from vault/specs with the size rule, workers, review and PR
argument-hint: <spec-name>
allowed-tools: Bash, Read, Edit, Grep, Glob, Skill, AskUserQuestion
---

Implement `vault/specs/$ARGUMENTS.md`. You are the orchestrator: plan, delegate, review. Keep your own reading small.

0. If `$ARGUMENTS` is empty, list the files in `vault/specs/` (skip `_template.md`), then ask the user which one with AskUserQuestion. If the user's message says to use workers, or to skip them, follow that instead of the size rule.
1. Read the spec. Open `vault/architecture/` notes only if the spec links them.
2. Load the `size-rule` skill and apply it. Say in one line whether you will do this directly or delegate, and why.
3. Work on a branch named `feat/<spec-name>`.
4. **Direct:** implement it yourself, with tests.
   **Delegate:** split it into subtasks. Write each task in clear, full English with a goal, the files, the acceptance check and the skills to use. Run each with
   `${CLAUDE_PLUGIN_ROOT}/scripts/deepseek_agent.sh --role builder "<task>"`
   (use `--role qa` for integration/E2E tests, `--role docs` for notes). For subtasks that touch different files, run them in parallel with `--worktree a` and `--worktree b` in one Bash call, then review with `git diff HEAD...worker/<name>`, `git merge --squash worker/<name>`, and remove the worktree and branch.
5. Review in this order: `git diff --stat`, `git diff <file>`, then the project's typecheck, lint and tests (commands are in `.claude/stack.json`).
6. Strikes: a strike is a worker exit code of 2, or checks failing on files that worker changed. First strike: rerun once with the exact error in the task. Two strikes on the same file: fix it yourself. Exit code 1: retry once, then do it yourself and note it in the PR. After a failed worker, check `git status` and revert files it left half-done.
7. Tick the checkboxes in the spec's `## Tasks` section only. Never change any other part of a spec.
8. Write `vault/changelog/<YYYY-MM-DD>-<spec-name>.md` (a worker with `--role docs` if the change was large, otherwise yourself).
9. Commit in Conventional Commits style, push the branch, open a PR that links the spec and the changelog note. Never push to the main branch.
