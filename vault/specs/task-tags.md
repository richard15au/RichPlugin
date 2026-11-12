---
title: Task tags
status: ready
tags: [spec]
---

## Goal
Each task can carry short tags, and the list can be filtered to the tasks with a given tag.

## Scope
- In: a tag list on every task, adding and removing tags, listing tasks by tag, showing tags in formatted output.
- Out: tag colours, renaming tags across tasks, tag search by prefix, persistence, a UI.

## Data changes
- `Task` gets `tags: string[]`; new tasks start with `[]`.

## API
- `TaskList.addTag(id, tag)` trims the tag, ignores a duplicate, returns the task; throws `Task <id> not found` or `Tag cannot be empty`.
- `TaskList.removeTag(id, tag)` returns the task; removing an absent tag is a no-op; throws `Task <id> not found` for a missing id.
- `TaskList.byTag(tag)` returns a copy of the tasks that have the tag, in their original order.
- `formatTask(task)` appends each tag as `#tag` after the title: `"[ ] (medium) Write tests #docs #urgent"`; no tags → unchanged.

## Acceptance checks
- [ ] `addTag`/`removeTag` behave as above (trim, no duplicates, no-op remove, both errors).
- [ ] `byTag` returns only matching tasks in original order and doesn't change `list()`.
- [ ] `formatTask` shows tags as `#tag`; existing format tests still pass; typecheck, lint, tests pass.

## Files likely involved
`src/tasks.ts`, `src/tasks.test.ts`, `src/format.ts`, `src/format.test.ts`.

## Tasks (orchestrator ticks these off as it goes)
- [ ] Tags on Task + addTag/removeTag/byTag with tests
- [ ] formatTask shows tags, tests updated
- [ ] Review + checks
- [ ] Changelog note
- [ ] PR opened
