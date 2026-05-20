# Frontend Architecture

The Flutter app follows feature-first architecture.

## Structure

- `app`: bootstrap, env, router, theme.
- `core`: shared widgets, config, errors, utilities.
- `data`: Drift tables, repositories, mappers, services.
- `features`: auth, onboarding, home, deferred meal editor, deferred journal, profile.
- `offline`: outbox and sync foundations.

## Rules

- Widgets render state and collect input.
- Riverpod controllers coordinate flows.
- Repositories own persistence and remote sync.
- Services wrap Supabase and platform dependencies.
- API payloads use generated contract DTOs.
- Local queries that return user data must filter by signed-in user ID.

Run `dart run build_runner build --delete-conflicting-outputs` after Drift table changes.
