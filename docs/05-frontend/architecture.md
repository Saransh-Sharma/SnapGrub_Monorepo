# Frontend Architecture

The Flutter app follows feature-first architecture.

## Structure

- `app`: bootstrap, env, router, theme.
- `core`: shared widgets, config, errors, utilities.
- `data`: Drift tables, repositories, mappers, services, including `meal_assets_local`.
- `features`: auth, onboarding, home, capture, photo analysis, meal editor, journal, progress, templates, custom foods, profile.
- `offline`: outbox and sync foundations.

## Rules

- Widgets render state and collect input.
- Riverpod controllers coordinate flows.
- Repositories own persistence and remote sync.
- Services wrap Supabase and platform dependencies.
- API payloads use generated contract DTOs.
- Local queries that return user data must filter by signed-in user ID.
- Phase 3 meal, template, and custom-food writes save locally first and sync through the outbox.

## Phase 3 Flow

Home quick actions route users to the Meal Editor, Journal, Progress, Templates, and Custom Foods. The Meal Editor is the reusable confirmation surface for manual, duplicate, and photo-analysis drafts now; barcode, OCR/text, and voice drafts should reuse it later.

Templates store meal snapshots. Custom foods create manual/custom food-ref items that can be inserted into meal drafts. Successful meal sync caches authoritative meals, daily rollups, and typed correction events.

Run `dart run build_runner build --delete-conflicting-outputs` after Drift table changes.

## Phase 4 Photo Flow

SnapStrip capture uses the `camera` plugin through the capture adapter, then `features/capture/data` normalizes orientation, re-encodes JPEG data to strip metadata, compresses under the target size, creates a thumbnail, hashes the bytes, and stores a local `meal_assets_local` row.

`features/photo_analysis` uploads the original and thumbnail to private Supabase Storage, calls `analysis-photo-create`, shows progress/failure states, and maps a completed analysis response into a `MealDraft(source: photo)`. The existing Meal Editor remains the confirmation surface before the meal is saved.
