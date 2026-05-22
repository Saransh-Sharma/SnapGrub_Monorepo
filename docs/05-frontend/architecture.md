# Frontend Architecture

The Flutter app follows feature-first architecture.

## Structure

- `app`: bootstrap, env, router, theme.
- `core`: shared widgets, config, errors, utilities.
- `data`: Drift tables, repositories, mappers, services, including `meal_assets_local`.
- `features`: auth, onboarding, home, capture, photo analysis, barcode, text entry, voice entry, meal editor, journal, progress, templates, custom foods, insights, profile, privacy.
- `offline`: outbox and sync foundations.

## Rules

- Widgets render state and collect input.
- Riverpod controllers coordinate flows.
- Repositories own persistence and remote sync.
- Services wrap Supabase and platform dependencies.
- API payloads use generated contract DTOs.
- Local queries that return user data must filter by signed-in user ID.
- Meal, template, custom-food, settings, upload, analytics, body-measurement, and export-request writes save locally first where supported and sync through the outbox.
- Destructive cloud account deletion is not an outbox command; it requires online authenticated confirmation and clears local data after success.

## Meal And Multimodal Flow

Home quick actions route users to the Meal Editor, Journal, Progress, Templates, Custom Foods, barcode, text, voice, and photo-analysis flows. The Meal Editor is the reusable confirmation surface for manual, duplicate, photo-analysis, barcode, label/OCR, text, and voice drafts.

Templates store meal snapshots. Custom foods create manual/custom food-ref items that can be inserted into meal drafts. Successful meal sync caches authoritative meals, daily rollups, and typed correction events.

Run `dart run build_runner build --delete-conflicting-outputs` after Drift table changes. The generated `lib/data/db/drift/app_database.g.dart` is committed because tests and CI import it directly.

## Phase 4 Photo Flow

SnapStrip capture uses the `camera` plugin through the capture adapter, then `features/capture/data` normalizes orientation, re-encodes JPEG data to strip metadata, compresses under the target size, creates a thumbnail, hashes the bytes, and stores a local `meal_assets_local` row.

`features/photo_analysis` uploads the original and thumbnail to private Supabase Storage, calls `analysis-photo-create`, shows progress/failure states, and maps a completed analysis response into a `MealDraft(source: photo)`. The existing Meal Editor remains the confirmation surface before the meal is saved.

## Phase 5-7 Flow

Barcode, OCR label assist, typed meal entry, and edited voice transcript entry call backend parser/resolver functions and map the results into editable meal drafts. Confirmed meals use the same local-first meal outbox as manual/photo meals.

Phase 6 sync status is visible from Home when commands fail or enter conflict and from the Sync status screen for detailed recovery. Phase 7 weekly insights and frequent-food defaults are cached locally and shown only when `weekly_insights.enabled` is active.

## Phase 8 Privacy Flow

Settings routes into `features/privacy` for:

- AI improvement consent.
- Cloud media storage and original photo retention.
- Export data.
- Delete account.
- Clear local data.

Privacy toggles use the existing `settings-patch` path and queue through `settings.patch` if the network failure is retryable. Export creation calls `exports-create` and displays the returned status, artifact expiry, and signed URL. Account deletion requires the user to type `DELETE`; after backend success the app clears local Drift data, signs out, and routes to Auth. Clear local data is intentionally separate from account deletion and only removes this device's cache.

See [privacy-export-delete.md](privacy-export-delete.md) for detailed UX and failure rules.
