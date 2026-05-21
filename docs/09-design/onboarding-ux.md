# Onboarding UX

Phase 1 onboarding collects enough profile and goal data to start the app without blocking on optional preferences.

## Current Decisions

- Cuisine and permission preferences are optional.
- Camera permission is not requested during onboarding primer.
- Metric and imperial inputs must be clear and converted to canonical server values before save.
- Invalid values should show actionable messages.
- Offline submit saves locally and shows pending sync state.

Camera/SnapStrip UX belongs to Home. Photo capture is implemented for Phase 4, so the Home surface should show graceful permission, loading, capture, analysis, retry, and manual fallback states. Barcode, OCR/text, and voice remain Phase 5+ actions and should stay visibly gated rather than hidden behind dead controls.
