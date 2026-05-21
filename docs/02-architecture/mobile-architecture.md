# Mobile Architecture

The Flutter app uses feature-first modules with Riverpod controllers, repositories/services, generated API contracts, and Drift local persistence.

## How It Works

- UI screens read Riverpod controllers and render state.
- Controllers coordinate user intent and navigation state.
- Repositories own local-first persistence, remote calls, and outbox behavior.
- Services wrap Supabase, device identity, and platform dependencies.
- Drift stores profile, goals, body measurements, devices, feature flags, meals, meal items, templates, custom foods, daily rollups, correction events, sync state, and outbox commands.

## Current Feature Slices

- `auth`, `onboarding`, and `profile`: sign-in, bootstrap, onboarding, settings, goals.
- `home` and `capture`: Home surface, SnapStrip camera preview, permission states, still capture, local compressed assets, thumbnails, hashes, and feature-gated actions.
- `photo_analysis`: uploads captured assets, calls analysis APIs, shows thumbnail-first progress/failure UX, and hands editable photo drafts to Meal Editor.
- `meal_editor` and `journal`: manual/duplicate meal source of truth, local save, edit, delete, duplicate.
- `progress`: local daily rollups for calories/macros and meal count.
- `templates`: reusable meal snapshots synced through RLS-backed `meal_templates`.
- `custom_foods`: user-owned foods synced through RLS-backed `custom_foods` and insertable into meal drafts.

## Safe Change Rules

- Keep platform and Supabase calls out of widgets.
- Pass authenticated `userId` into local profile/goal reads.
- Save profile/goal locally before attempting remote settings sync.
- Use generated API DTOs from `snapgrub_api_contracts` for function payloads.
- Keep Phase 5 barcode/OCR/voice work behind explicit contracts and feature flags.
- Photo analysis output must enter the existing Meal Editor as an editable draft, not a parallel save path.

Current app source starts in `apps/mobile/lib/main.dart`.
