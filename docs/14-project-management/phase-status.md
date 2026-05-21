# Phase Status

## Current Phase

Phase 0-5 implementation is in place at source level. Current work is Phase 6 readiness: verification, native platform restoration, and offline sync/idempotency hardening.

## Capability Map

```mermaid
flowchart LR
  P0["Phase 0\nrepo/contracts/env"]
  P1["Phase 1\nauth/onboarding/profile"]
  P2["Phase 2\nHome + SnapStrip shell"]
  P3["Phase 3\nmeal ledger + local-first sync"]
  P4["Phase 4\nphoto analysis"]
  P5["Phase 5\nbarcode/OCR/text/voice"]
  P6["Phase 6\noffline sync hardening"]

  P0 --> P1 --> P2 --> P3 --> P4 --> P5 --> P6
```

## Implemented

- Contract generation/check flow exists.
- Supabase migrations cover identity, goals, devices, flags, analytics, body measurements, storage, settings RPC, meal core, photo analysis tables, RLS, and idempotency.
- Edge Functions exist for bootstrap, settings patch, events ingest, and meals.
- Flutter app has auth/onboarding/profile/local-first scaffolding.
- Outbox supports settings, meal, template, and custom-food commands.
- RLS isolation harness exists.
- Numbered documentation system is being established.
- Phase 3 meal schema, local meal tables, and `meals` Edge Function exist.
- Meal Editor, Journal, Progress, Templates, Custom Foods, rollups, and correction-event caching exist.
- Phase 4 photo-analysis contracts, migrations, Edge Functions, local capture asset pipeline, and Meal Editor draft handoff exist.
- Phase 5 barcode, OCR assist, text entry, voice entry, catalog migration, and parser Edge Functions exist.
- Phase 6 readiness now includes idempotent template/custom-food/body-measurement/export functions, analytics idempotency, server-owned daily rollups, idempotency cleanup, and expanded mobile outbox command support.

## Verification Blockers

- Flutter/Dart/Supabase CLI/Deno toolchain must be installed in the execution environment.
- Real Flutter Android/iOS platform projects must be generated and committed.
- Android/iOS platform folders currently contain only `.gitkeep`; real flavor projects remain a Phase 0 compliance gap.
- Supabase local env keys must be exported before RLS and meal-core smoke tests are authoritative.

## Next Phase Entry

Proceed to Phase 6 acceptance only after Phase 5 smoke tests pass, real platform folders are generated, and the full backend/mobile toolchain is available locally or in CI.
