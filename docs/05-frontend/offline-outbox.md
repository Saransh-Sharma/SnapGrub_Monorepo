# Frontend Offline Outbox

The mobile outbox supports `settings.patch`, meal/template/custom-food commands, and Phase 6 sync-readiness commands for assets, analytics, body measurements, and exports.

## Behavior

- `saveOnboarding` validates draft data before local write.
- Local profile/goal data is stored with `pending` sync status before remote sync.
- Retryable remote failures enqueue `settings.patch` with `client_request_id`.
- Meal commands use `meal.create`, `meal.update`, and `meal.delete` against the `meals` Edge Function.
- Template commands use `template.upsert` and `template.delete` through the `meal-templates` Edge Function.
- Custom-food commands use `custom_food.upsert` and `custom_food.delete` through the `custom-foods` Edge Function.
- Phase 6 commands include `asset.upload`, `analytics.batch`, `body_measurement.create`, and `export.create`.
- Foreground, login, network-restored, manual sync, and pull-to-refresh drains pending commands for the signed-in user.
- Successful drain marks commands `synced` and caches the server response.
- Meal sync caches authoritative meals, daily rollups, and correction events.
- Photo asset upload is represented as `asset.upload`; photo analysis creation still runs immediately after an upload-capable path is available.
- Once the analysis result opens in Meal Editor, the confirmed photo meal uses the existing local-first meal outbox with `source=photo`, `analysis_job_id`, and `photo_asset_id`.
- Validation/auth failures are marked failed, idempotency/revision conflicts are marked conflict, and retryable failures use exponential backoff with jitter.

## Safe Change Rules

- Keep commands user-scoped.
- Keep replay idempotent with `client_request_id`.
- Keep Phase 5 barcode/OCR/voice parser calls out of the durable outbox; only confirmed meal saves enter the meal outbox.
- Update backend idempotency docs when replay behavior changes.
- Template snapshots must remain self-contained enough to create a duplicate meal draft.
- Custom-food insertion should preserve `food_ref_kind`, `custom_food_id`, and source metadata on meal items.
- Cache typed correction events from meal responses into `correction_events_local`.
