# Frontend Offline Outbox

The mobile outbox supports `settings.patch` plus Phase 3 meal, template, and custom-food commands.

## Behavior

- `saveOnboarding` validates draft data before local write.
- Local profile/goal data is stored with `pending` sync status before remote sync.
- Retryable remote failures enqueue `settings.patch` with `client_request_id`.
- Meal commands use `meal.create`, `meal.update`, and `meal.delete` against the `meals` Edge Function.
- Template commands use `template.upsert` and `template.delete` against RLS-backed `meal_templates`.
- Custom-food commands use `custom_food.upsert` and `custom_food.delete` against RLS-backed `custom_foods`.
- Bootstrap and manual refresh drain pending commands for the signed-in user.
- Successful drain marks commands `synced` and caches the server response.
- Meal sync caches authoritative meals, daily rollups, and correction events.
- Phase 4 photo asset upload and analysis creation are immediate API/storage operations, not outbox commands.
- Once the analysis result opens in Meal Editor, the confirmed photo meal uses the existing local-first meal outbox with `source=photo`, `analysis_job_id`, and `photo_asset_id`.
- Validation/auth/idempotency conflicts are not requeued.

## Safe Change Rules

- Keep commands user-scoped.
- Keep replay idempotent with `client_request_id`.
- Keep Phase 5 barcode/OCR/voice commands out of the outbox until their server contracts exist.
- Update backend idempotency docs when replay behavior changes.
- Template snapshots must remain self-contained enough to create a duplicate meal draft.
- Custom-food insertion should preserve `food_ref_kind`, `custom_food_id`, and source metadata on meal items.
- Cache typed correction events from meal responses into `correction_events_local`.
