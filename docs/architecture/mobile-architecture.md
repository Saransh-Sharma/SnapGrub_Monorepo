# Mobile Architecture

The mobile app uses feature-first Flutter architecture with Riverpod controllers, repositories, services, and Drift local persistence.

Rules for Phase 0-1:

- Use `AsyncNotifier` for auth/session/bootstrap state.
- Use `Notifier` for onboarding draft state.
- Keep Supabase, Drift, and platform integrations in services/repositories.
- UI reads controllers and does not call Supabase tables directly.
- Save profile and goal locally before attempting remote settings sync.
