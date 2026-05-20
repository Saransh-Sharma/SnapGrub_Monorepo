# Manual Test Plan

The current manual QA checklist is maintained in [../qa/manual-test-plan.md](../qa/manual-test-plan.md).

Phase 0/1 manual smoke must cover:

- Fresh install opens Auth.
- Authenticated user without profile enters Onboarding.
- Onboarding saves locally with network unavailable.
- Bootstrap/refresh drains pending settings when online.
- Relaunch lands on Home after onboarding.
- Second signed-in user does not see first user's cached profile/goal.
- Settings goal edit persists through the same settings path.
