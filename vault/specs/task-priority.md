---
title: Task priority
status: ready
tags: [spec]
---

## Goal
Each task has a priority, and the list can be shown with the most important tasks first.

## Scope
- In: a priority on every task, changing it, listing tasks sorted by priority, showing it in formatted output.
- Out: due dates, persistence, a UI, priority levels beyond the three below.

## Data changes
- `Task` gets `priority: "low" | "medium" | "high"`.
- New tasks default to `"medium"`; `add(title, priority?)` accepts an optional priority.

## API
- `TaskList.setPriority(id, priority)` returns the updated task; throws `Task <id> not found` for a missing id.
- `TaskList.byPriority()` returns a copy of the tasks ordered high → medium → low; tasks with the same priority keep their original order.
- `formatTask(task)` becomes `"[x] (high) Ship it"` / `"[ ] (low) Write tests"` — the priority in brackets after the checkbox.

## Acceptance checks
- [ ] New tasks default to medium; `add` accepts an explicit priority.
- [ ] `setPriority` changes it and throws for a missing id.
- [ ] `byPriority` orders high → medium → low and is stable within a priority.
- [ ] `byPriority` doesn't change the order returned by `list()`.
- [ ] `formatTask` includes the priority; existing format tests updated to match.
- [ ] `npm run typecheck`, `npm run lint`, `npm test` all pass.

## Files likely involved
`src/tasks.ts`, `src/tasks.test.ts`, `src/format.ts`, `src/format.test.ts`.

## Tasks (orchestrator ticks these off as it goes)
- [ ] Priority on Task + add/setPriority/byPriority with tests
- [ ] formatTask shows priority, tests updated
- [ ] Review + checks
- [ ] Changelog note
- [ ] PR opened
