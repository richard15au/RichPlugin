---
name: obsidian-docs
description: "Format rules for notes in vault/ (frontmatter, wikilinks, changelog layout). Use whenever writing or editing a vault note."
---

# Obsidian note rules

Write notes for a human reading them in Obsidian later. Plain, clear English — no telegraphic style.

## Every note starts with YAML frontmatter
```
---
title: <human title>
date: YYYY-MM-DD
tags: [changelog, <area>]
spec: "[[<spec-file-name-without-.md>]]"
---
```

## Body
- `## What changed` — 2–5 bullets in plain language.
- `## Why` — one short paragraph linking the spec: `[[spec-name]]`.
- `## Files` — bullet list of changed paths in backticks.
- `## Follow-ups` — only if something was deliberately left out; otherwise omit.

## Syntax
- Link other vault notes with `[[note-name]]` (no `.md`, no paths unless names clash).
- Tags in frontmatter, lowercase, hyphenated (`course-enrolment`). Don't scatter inline `#tags` in the body.
- Mermaid diagrams in fenced ```mermaid blocks are fine for architecture notes.
- Never edit files in `vault/specs/`.
