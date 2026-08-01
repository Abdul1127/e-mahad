# AGENTS.md — E-Ma'had

## Project Identity

This repository is exclusively for E-Ma'had.

Do not import assumptions, architecture, conventions, workflows,
or requirements from other projects.

## Development Workflow

The developer manually reviews and copies code into VS Code.

When proposing code changes:

1. Explain the purpose of the stage.
2. Explain what the developer must do.
3. Show the affected folder structure.
4. State the exact path of every file.
5. Provide complete file contents.
6. Do not provide partial snippets when a complete file is needed.
7. List validation commands.
8. State completion criteria.

## Package Manager

Use npm only.

Do not use:

- pnpm
- yarn
- bun

## Supabase

The project uses Supabase Cloud directly.

Do not require:

- Supabase CLI
- Docker
- Local Supabase
- Local PostgreSQL

Database SQL is stored under:

database/sql/

The developer manually runs SQL through Supabase SQL Editor.

## Technology

- Next.js App Router
- TypeScript
- Tailwind CSS
- Supabase PostgreSQL
- Supabase Auth
- Supabase Storage
- Vercel
- npm

## Product Context

E-Ma'had is a centralized pesantren information system.

Its domains include:

- Users and roles
- Staff
- Students
- Guardians
- Classes
- Tahfiz groups
- Staff assignments
- Care journals
- Tahfiz weekly reports
- Tahsin Clinic
- Billing and payments
- Head of Ma'had journals
- Guardian dashboard
- Excel and Google Sheets import/export

Supabase PostgreSQL is the transactional source of truth.

Google Sheets must not be used as transactional storage.

## Required Reading

Before making changes, read:

1. docs/01-project-overview.md
2. docs/02-development-roadmap.md
3. docs/03-technical-decisions.md
4. docs/04-open-questions.md

Read additional documents when they become available.

## Architecture Rules

- Use Next.js App Router.
- Use TypeScript.
- Use Server Components by default.
- Add "use client" only when necessary.
- Keep page and route files thin.
- Place business logic under src/features.
- Place shared infrastructure under src/lib.
- Place reusable UI under src/components.
- Do not use `any`.
- Validate all user input.
- Resolve the authenticated user on the server.
- Never trust role identifiers sent by the browser.
- Never expose Supabase secret keys to client-side code.

## Authentication Rules

- Authentication uses Supabase Auth.
- Browser and server clients use @supabase/ssr.
- Server authorization must validate identity.
- Do not use client-side route hiding as security.
- Do not rely on getSession() alone for server authorization.

## Database Rules

- Store SQL files under database/sql.
- Every schema change must be documented.
- Use UUID primary keys unless documented otherwise.
- Add foreign keys.
- Add indexes for frequently filtered foreign keys.
- Add unique constraints for duplicate-sensitive transactions.
- Add check constraints.
- Enable RLS.
- Add policies before exposing data to the client.
- Do not use service-role access to bypass normal user access.
- Store legacy spreadsheet IDs as separate columns.
- Do not use legacy IDs as internal primary keys.

## Security Rules

- Authentication is not authorization.
- Role is not always the same as data scope.
- Assignment determines operational data access.
- Guardians may only access linked students.
- Internal notes must not automatically be visible to guardians.
- Draft records and submitted records must have different edit rules.
- Sensitive changes should record the acting user.

## Scope Control

Only implement the currently requested stage.

Do not create future features merely because they appear in the
roadmap.

Do not create placeholder database tables without an approved
workflow and design.

## Completion Report

After completing a task, report:

- Summary
- Files added
- Files updated
- SQL files added
- Database objects changed
- RLS policies changed
- Tests executed
- Commands executed
- Remaining risks
- Open questions