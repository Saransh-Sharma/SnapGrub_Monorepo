# Manual QA Plan

Phase 0:

- Run OpenAPI validation.
- Run Supabase migrations locally.
- Launch mobile dev flavor after Flutter platform bootstrap.

Phase 1:

- Fresh install opens Auth.
- Authenticated user without onboarding lands on Onboarding.
- Metric and imperial onboarding validate.
- Offline final submit saves locally and queues `settings.patch`.
- Reconnect syncs the outbox command.
- Settings can edit profile and active goal.

Phase 2:

- Home shows SnapStrip, daily progress, macro summary, recent meals, and quick actions.
- SnapStrip follows `snapstrip.enabled`.
- Camera permission-needed state leaves barcode, text, voice, and manual affordances visible.
- Capture tap does not upload an image.
- SnapStrip analytics events are accepted by `events-ingest`.

Phase 3:

- Manual meal can be created with one or more items.
- Saved meal appears immediately in Today journal and progress totals.
- Edit, duplicate, and delete work while offline.
- Reconnect and run sync; no duplicate meal appears.
- Cross-user RLS blocks meals, meal items, templates, custom foods, rollups, and correction events.
