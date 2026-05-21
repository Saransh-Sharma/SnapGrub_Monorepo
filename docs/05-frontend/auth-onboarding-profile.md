# Auth, Onboarding, And Profile

Phase 1 lets users authenticate, bootstrap app-start state, complete onboarding, and edit profile goals.

## Flow

1. `AuthController` reads Supabase session state.
2. Signed-out users route to Auth.
3. Signed-in users call `profile-bootstrap`.
4. Users without completed profile/goal state enter onboarding.
5. Onboarding edits an `OnboardingDraft`.
6. Final submit saves locally first and then calls `settings-patch`.
7. Settings goal edit reuses the same repository/settings path.

## Safe Change Rules

- Never show cached profile data without the current authenticated `userId`.
- Stable install ID must persist across bootstraps.
- Do not request camera/microphone permissions during onboarding primer.
- Keep validation messages field-level where possible.
- Treat offline save as pending sync, not final server success.
