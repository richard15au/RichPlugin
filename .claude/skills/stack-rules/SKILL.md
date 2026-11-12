---
name: stack-rules
description: "Conventions for this test project: a small TypeScript module with Vitest tests and ESLint. Use before writing or reviewing any code here."
---

# Stack rules — TypeScript + Vitest (test project)

This repo exists to test the agent setup. Keep changes small and conventional.

## Layout
- Source in `src/<name>.ts`; tests next to it as `src/<name>.test.ts`.
- One module per concept. Export only what other code or tests need.

## TypeScript
- `strict` and `noUncheckedIndexedAccess` are on. No `any`, no `@ts-ignore`, no non-null `!` to silence errors — narrow instead.
- Prefer plain functions and small classes; no new dependencies.
- Throw `Error` with a clear message for invalid input; never return error objects.

## Tests (Vitest)
- Every new function or behaviour gets tests: the normal case, edge cases (empty, missing, duplicate), and the error case.
- Test names describe behaviour ("rejects an empty title"), not implementation.

## Checks (all must pass)
- `npm run typecheck`
- `npm run lint`
- `npm test`
