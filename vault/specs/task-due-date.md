---
title: Task due date
status: ready
tags: [spec]
---

## Goal
Each task can have an optional due date, and the list can show which open tasks are overdue.

## Scope
- In: an optional due date on every task, setting and clearing it, listing overdue tasks, showing it in formatted output.
- Out: times of day, time zones, reminders, recurring tasks, date libraries, persistence, a UI.

## Data changes
- `Task` gets `due?: string` in `YYYY-MM-DD` form; new tasks have no due date.

## API
- `TaskList.setDue(id, due)` sets the date (or clears it when `due` is `undefined`), returns the task; throws `Task <id> not found` or `Invalid due date`.
- A valid date matches `YYYY-MM-DD` and is a real calendar date (`2026-02-30` is invalid).
- `TaskList.overdue(today)` returns a copy of the open tasks whose due date is before `today`, in their original order.
- `formatTask(task)` appends `(due YYYY-MM-DD)` after the title: `"[ ] (high) Pay rent (due 2026-12-01)"`; no due → unchanged.

## Acceptance checks
- [ ] `setDue` sets, clears and validates as above (format, real date, both errors).
- [ ] `overdue` skips done and undated tasks, excludes `today` itself, keeps original order, doesn't change `list()`.
- [ ] `formatTask` shows the due date; existing format tests still pass; typecheck, lint, tests pass.

## Files likely involved
`src/tasks.ts`, `src/tasks.test.ts`, `src/format.ts`, `src/format.test.ts`.

## Tasks (orchestrator ticks these off as it goes)
- [ ] Due date on Task + setDue/overdue with tests
- [ ] formatTask shows due date, tests updated
- [ ] Review + checks
- [ ] Changelog note
- [ ] PR opened
