---
title: Task due date
date: 2026-11-12
tags: [changelog, tasks]
spec: "[[task-due-date]]"
---

## What changed
- `Task` gets an optional `due` date in `YYYY-MM-DD` form; new tasks have none.
- New `TaskList.setDue(id, due)` sets the date, or clears it when `due` is `undefined`, and returns the task. It throws `Task <id> not found` or `Invalid due date` (bad format or a non-existent calendar date such as `2026-02-30`).
- New `TaskList.overdue(today)` returns a copy of the open tasks due strictly before `today`, in original order, leaving `list()` untouched.
- `formatTask` appends `(due YYYY-MM-DD)` after the title, for example `[ ] (high) Pay rent (due 2026-12-01)`; tasks without a due date format as before.

## Why
This implements [[task-due-date]]: an optional due date per task and a way to find overdue open tasks, without times, time zones, reminders, persistence or a UI. Tests in `src/tasks.test.ts` and `src/format.test.ts` cover setting, clearing, validation, the overdue rules and the new format.

## Files
- `src/tasks.ts`
- `src/tasks.test.ts`
- `src/format.ts`
- `src/format.test.ts`
