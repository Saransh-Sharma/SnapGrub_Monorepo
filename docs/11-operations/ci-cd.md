# CI/CD

GitHub Actions configuration lives in `.github/workflows/ci.yml`.

## Jobs

- `contracts-and-backend`
  - `npm ci`
  - OpenAPI validation and generated client freshness
  - Deno setup and Edge Function typecheck
  - migration lint
  - Supabase start/reset
  - RLS isolation harness
  - meal-core smoke harness
  - auth/profile, photo-analysis, multimodal, offline-sync, insights, and privacy backend smoke harnesses

- `mobile`
  - Flutter setup
  - platform folder check
  - pub get
  - build runner
  - format, analyze, tests
  - dev flavor APK build

CI is not fully authoritative for release until:

- Mobile analyze/test/build pass with the same Flutter version used for release.
- iOS simulator or device build runs on a macOS runner.
- Staging deployment validates real provider secrets and scheduled jobs.
- Privacy export/delete smoke runs against staging before production promotion.

The `/packages/` directory contains source-controlled API contracts and generated clients. Keep it explicitly unignored even though Swift Package Manager ignores `Packages/`.
