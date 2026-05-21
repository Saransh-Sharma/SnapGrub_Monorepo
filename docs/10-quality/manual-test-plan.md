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
