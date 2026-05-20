# Onboarding UX

Phase 1 onboarding collects enough profile and goal data to start the app without blocking on optional preferences.

## Current Decisions

- Cuisine and permission preferences are optional.
- Camera permission is not requested during onboarding primer.
- Metric and imperial inputs must be clear and converted to canonical server values before save.
- Invalid values should show actionable messages.
- Offline submit saves locally and shows pending sync state.

Future camera/SnapStrip UX belongs in Phase 2 docs after readiness gates pass.
