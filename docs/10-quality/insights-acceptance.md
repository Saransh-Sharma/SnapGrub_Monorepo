# Insights Acceptance

## Automated

- `npm run backend:test:insights`
- `npx --yes deno test --allow-env services/backend/supabase/tests/unit/weekly_insight_builder_test.ts`
- `cd apps/mobile && flutter test test/unit/features/insights`
- `flutter analyze`
- `flutter test`

## Manual

- With `weekly_insights.enabled` disabled, Progress and Home render without weekly insight surfaces.
- With `weekly_insights.enabled` enabled for the test user/build, generated weekly insight data appears in Progress.
- With `smart_foods_v2.enabled` disabled, existing frequent-food behavior remains available.
- With `smart_foods_v2.enabled` enabled, Smart repeats show ranked suggestions from learned defaults, recent meals, and templates.
- Tapping a Smart repeat opens Meal Editor with an editable draft and does not persist a meal until Save is tapped.
- Frequent-food/default suggestions reflect saved meals and do not overwrite user edits.
- Local caches survive relaunch and stay user-scoped across sign-out/sign-in.
- Empty or insufficient meal history shows a quiet empty state rather than fabricated guidance.
- Scheduled/cron weekly generation is verified in staging before production enablement.
