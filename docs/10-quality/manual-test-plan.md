# Manual Test Plan

The current manual QA checklist is maintained here for numbered docs. Legacy checklist notes remain in [../qa/manual-test-plan.md](../qa/manual-test-plan.md).

## Phase 0/1 Foundation Smoke

- Fresh install opens Auth.
- Authenticated user without profile enters Onboarding.
- Onboarding saves locally with network unavailable.
- Bootstrap/refresh drains pending settings when online.
- Relaunch lands on Home after onboarding.
- Second signed-in user does not see first user's cached profile/goal.
- Settings goal edit persists through the same settings path.

## Phase 2/3 Manual Smoke

- Home shows SnapStrip shell and disabled controls when feature flags are off.
- Create a manual meal with one item while offline; Journal updates immediately.
- Edit meal title, time, quantity, unit, grams, and macros.
- Delete a meal and confirm Progress rollup decreases.
- Relaunch app and confirm local meals, templates, custom foods, and progress persist.
- Reconnect and sync; meal status becomes synced and authoritative rollup/correction events cache locally.
- Duplicate a meal from Journal and verify it creates a new pending meal.
- Save a meal as a template, then use that template to create a duplicate meal.
- Create a custom food and insert it into a meal draft.
- Sign in as a second user and verify no first-user local data appears.

## Phase 4/5 Manual Smoke

- Camera permission denied/granted states are clear and recoverable.
- Backgrounding Home pauses preview; foregrounding resumes preview when permission exists.
- Photo capture uploads/retries cleanly and opens an editable photo draft in Meal Editor.
- Barcode scan resolves a packaged product or offers manual fallback.
- OCR label assist parses label text into an editable draft.
- Text meal entry maps parser output into Meal Editor.
- Voice permission denial is handled without losing the typed/manual fallback.

## Phase 6/7 Manual Smoke

- Offline meal save appears immediately and syncs after reconnect.
- Failed or conflict sync state is visible from Home and opens the Sync status screen.
- Pending commands are linked to recoverable user action where possible.
- `exports-create` creates an export request only; no artifact should be expected in Phase 6.
- Weekly insight widgets stay hidden while `weekly_insights.enabled` is disabled.
- Enabling `weekly_insights.enabled` shows cached/generated insight/default surfaces without breaking Progress.
