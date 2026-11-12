---
name: size-rule
description: "Decide whether a coding subtask is done directly by Claude or delegated to a DeepSeek worker. Use before delegating anything, and when planning a spec."
---

# Size rule: direct or delegate?

Delegating has a fixed cost for Claude: reading the spec, writing the worker task, reviewing the diff. On a small job that cost equals writing the code yourself. Test 8 (Nov 2026, a 3-check spec on Sonnet 5.5): workers cost Claude about $0.10, Claude alone about $0.09. A tie, so small jobs go direct.

## Decide per spec, then per subtask
Estimate the total change first (files touched, lines added or changed).

**Do it yourself** when any of these hold:
- the whole spec touches at most 2 files and about 60 changed lines;
- it is a one-line fix, a config change, a rename or a small doc edit;
- the task text you would write is as long as the code.

**Delegate** when any of these hold:
- 3 or more files, or about 80+ changed lines in total;
- a test suite or integration/E2E tests to write (QA role);
- independent subtasks that can run in parallel in worktrees;
- documentation for a larger change (docs role).

**Never delegate:** security or permission design, data migrations, architecture decisions, anything touching secrets.

## Rules of thumb
- One worker per coherent subtask, not one per file. Each worker run carries about 14k tokens of fixed overhead on the DeepSeek side.
- Thresholds can be changed per project in `.claude/stack.json` (`size_rule`). The defaults are provisional until a bigger test is run.
- Small spec: write the changelog note yourself in a few lines. Large spec: send it to the docs role.
- Say in one line which way you chose and why before starting.
