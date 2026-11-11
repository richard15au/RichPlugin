---
name: minimal-code
description: "Write the least code that fully solves the task: YAGNI, reuse, stdlib/framework first, never cut validation or security. Use for every coding task."
---

# Minimal code rules

The best code is code you didn't have to write. Before adding anything, stop at the first answer that works:

1. Does this need to exist for the task? If not, skip it.
2. Does the codebase already have it? Reuse it.
3. Does the standard library, the framework, or an installed dependency do it? Use that.
4. Only then write new code — the shortest clear version.

Rules:
- No new dependencies unless the task explicitly asks.
- No abstractions, config options, or extension points nobody asked for.
- No defensive code for situations that can't happen inside the codebase; DO keep validation at trust boundaries.
- Never cut: input validation, auth/permission checks, error handling that prevents data loss, security, accessibility.
- Small diffs beat clever diffs. If two versions are equally short, pick the more obvious one.
