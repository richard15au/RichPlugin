---
name: ui-design
description: "How to design and build UI in this app so it looks considered, not templated: layout, hierarchy, spacing, colour, states and accessibility with Tailwind. Use for any page, component or form work."
---

# UI design rules

Aim for calm, clear, purposeful screens. Every element earns its place.

## Before building
- Name the one main thing the user does on this screen. Make it the most visible action; everything else is secondary.
- Sketch the hierarchy in words first: page title → primary action → main content → secondary info.
- Reuse existing components in `src/components/` before making new ones.

## Layout & spacing
- Use Tailwind's spacing scale consistently: `gap-2/3` inside a component, `gap-6/8` between sections, `p-4`–`p-6` for cards.
- Constrain reading width (`max-w-3xl` for forms/text, `max-w-6xl` for dashboards). Align to a single left edge.
- Group related things with spacing first, borders second, background colour last.

## Type & colour
- Max 3 text sizes per screen (e.g. `text-2xl` title, `text-base` body, `text-sm` meta). Weight and colour carry hierarchy, not size alone.
- Neutral base (`slate`/`zinc`), ONE accent colour for primary actions and focus. Red only for destructive/error, green only for success.
- Muted text uses `text-slate-500/600`, never lighter — keep contrast at WCAG AA (4.5:1).

## Every data view needs all four states
- Loading (skeleton matching the final layout, not a spinner in the void)
- Empty (one line explaining why + the action to fix it, e.g. "No courses yet — Create course")
- Error (plain-language message + retry)
- Populated

## Forms
- Label above input, helper text below, error text replaces helper text in red with `aria-describedby`.
- Disable the submit button while submitting and show progress; never double-submit.
- Destructive actions (delete course, remove student) need a confirm step naming the thing being deleted.

## Accessibility (never skipped)
- Real `<button>`/`<a>` elements, visible focus ring (`focus-visible:ring-2`), keyboard reachable.
- Images get `alt`; icon-only buttons get `aria-label`.
- Tables for tabular data (`<th scope>`), not div grids.

## Avoid
- Gradients, drop shadows on everything, emoji as icons, centred body text, more than one primary button per view, placeholder text used as a label.
