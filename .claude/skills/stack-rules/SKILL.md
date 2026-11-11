---
name: stack-rules
description: "Conventions for this T3 + PostgreSQL app: tRPC routers, Prisma schema, Next.js App Router, NextAuth, Tailwind. Use before writing or reviewing any app code."
---

# Stack rules — T3 (Next.js, TypeScript, tRPC, Prisma, NextAuth, Tailwind) + PostgreSQL

Edit this file as your conventions settle. Workers follow it literally.

## TypeScript
- `strict` mode; no `any`, no `@ts-ignore`. Use `unknown` and narrow it.
- Infer types from Prisma and tRPC (`RouterOutputs`, `Prisma.CourseGetPayload<...>`) instead of hand-writing duplicates.

## tRPC
- Routers live in `src/server/api/routers/<entity>.ts` and are registered in `src/server/api/root.ts`.
- Every procedure has a Zod `.input()` schema. Use `protectedProcedure` for anything touching user data; `publicProcedure` only for truly public reads.
- Authorise by role/ownership inside the procedure (e.g. instructor owns the course) — being logged in is not enough.
- Throw `TRPCError` with the right code (`NOT_FOUND`, `FORBIDDEN`, `BAD_REQUEST`); never return error objects.

## Prisma / PostgreSQL
- Schema changes go in `prisma/schema.prisma`; models PascalCase singular (`Course`, `Enrollment`), fields camelCase.
- Every model has `id String @id @default(cuid())`, `createdAt`, `updatedAt @updatedAt`.
- Add `@@index` for foreign keys and anything filtered on. Use `@@unique` for natural keys (e.g. `[userId, courseId]` on Enrollment).
- Multi-step writes go in `ctx.db.$transaction`. Select only the fields the caller needs.
- Never write migrations by hand and never suggest `migrate reset`; a human runs `prisma migrate dev`.

## Next.js / UI
- App Router. Server components by default; add `"use client"` only for interactivity.
- Call the API through the tRPC React hooks (`api.course.list.useQuery`) on the client and the server caller in server components.
- Tailwind utility classes only; no new CSS files. Forms need labels, and buttons need accessible names.

## Naming & files
- Components PascalCase (`CourseCard.tsx`), hooks `useX`, everything else camelCase.
- Tests sit next to code as `*.test.ts`.
