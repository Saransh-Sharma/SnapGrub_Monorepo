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

- `mobile`
  - Flutter setup
  - platform folder check
  - pub get
  - build runner
  - format, analyze, tests
  - dev flavor APK build

CI is not fully authoritative until real Android/iOS platform projects are committed.
