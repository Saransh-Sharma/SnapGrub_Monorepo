# Onboarding UX

Phase 1 onboarding collects enough profile and goal data to start the app without blocking on optional preferences.

## Current Decisions

- Cuisine and permission preferences are optional.
- Camera permission is not requested during onboarding primer.
- Metric and imperial inputs must be clear and converted to canonical server values before save.
- Invalid values should show actionable messages.
- Offline submit saves locally and shows pending sync state.

Camera/SnapStrip UX belongs to Home. Photo capture is implemented for Phase 4, and barcode, OCR/text, and voice entry are implemented as Phase 5 draft-entry paths. Home should continue to show graceful permission, loading, retry, transcript/edit, low-confidence fallback, and manual edit states instead of hiding available actions behind dead controls.
