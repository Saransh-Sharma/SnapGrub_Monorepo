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
- `export.create` can queue locally, but Phase 8 artifact generation occurs only after it drains through `exports-create` online.
- Weekly insight widgets stay hidden while `weekly_insights.enabled` is disabled.
- Enabling `weekly_insights.enabled` shows cached/generated insight/default surfaces without breaking Progress.

## Phase 8 Manual Smoke

- Open Settings and verify Privacy is visible.
- Toggle AI improvement consent online and offline; confirm profile state persists and syncs.
- Toggle cloud media storage and save original photos online and offline.
- Create a JSON export with no meals and confirm completed state plus signed URL.
- Create a CSV export with at least one meal/item and confirm rows are present in the artifact during backend/staging checks.
- Poll an existing export and confirm the signed URL refreshes when needed.
- Attempt account deletion without typing `DELETE`; confirm it is blocked.
- Delete a test account with `DELETE`; confirm user is signed out and relaunch lands on Auth.
- Clear local data on a separate test account; confirm signing in again restores cloud data rather than deleting the account.

## Phase 9 Beta Hardening Smoke

- Confirm crash reporting initializes in staging/beta build once provider is configured.
- Confirm analytics events appear for onboarding, capture, analysis, meal save, sync, export, delete, and insight interactions.
- Enable large text and complete onboarding, meal editor, export, and delete-account screens without clipped controls.
- Run VoiceOver/TalkBack through Auth, Home, Meal Editor, Export, Delete Account, and Sync status.
- Force a photo-analysis failure and confirm retry/manual fallback.
- Force export failure and confirm user-visible error plus retry.
- Force sync conflict and confirm recovery entry point remains visible.

## Phase 10 Release Candidate Smoke

- Fresh install, sign in, complete onboarding in under 2 minutes.
- Capture photo, receive draft, edit portion, save meal, verify Journal/Progress.
- Scan barcode known and unknown products.
- Parse text and voice meal entries into the same Meal Editor.
- Save offline manual meal, relaunch, reconnect, and confirm no duplicate.
- Request export, copy signed URL, and confirm it expires.
- Delete account and confirm no subsequent login session remains.
- Verify staging dashboards show no P0/P1 crash or API regression during smoke.
