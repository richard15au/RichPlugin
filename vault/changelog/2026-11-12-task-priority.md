---
title: Task priority
date: 2026-11-12
tags: [changelog, tasks]
spec: "[[task-priority]]"
---

## What changed
- Every task now carries a priority of `low`, `medium` or `high`, exposed as the new `Priority` type.
- `TaskList.add(title, priority?)` defaults new tasks to `medium` but accepts an explicit priority.
- New `TaskList.setPriority(id, priority)` changes a task's priority and returns it, throwing `Task <id> not found` if the id is unknown.
- New `TaskList.byPriority()` returns a copy of the tasks ordered high → medium → low, keeping the original order within each priority and leaving `list()` untouched.
- `formatTask` now includes the priority, for example `[x] (high) Ship it`.

## Why
This implements [[task-priority]], which asked for a priority on every task and a way to show the most important tasks first without adding due dates, persistence or a UI. Tests were added or updated in `src/tasks.test.ts` and `src/format.test.ts` to cover the new default, `setPriority`, the stable ordering and the new format output.

## Files
- `src/tasks.ts`
- `src/tasks.test.ts`
- `src/format.ts`
- `src/format.test.ts`
