# Insights Acceptance

## Automated

- `npm run backend:test:insights`
- `flutter analyze`
- `flutter test`

## Manual

- With `weekly_insights.enabled` disabled, Progress and Home render without weekly insight surfaces.
- With `weekly_insights.enabled` enabled for the test user/build, generated weekly insight data appears in Progress.
- Frequent-food/default suggestions reflect saved meals and do not overwrite user edits.
- Local caches survive relaunch and stay user-scoped across sign-out/sign-in.
- Empty or insufficient meal history shows a quiet empty state rather than fabricated guidance.
- Scheduled/cron weekly generation is verified in staging before production enablement.
