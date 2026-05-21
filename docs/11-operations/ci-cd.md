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

- `mobile`
  - Flutter setup
  - platform folder check
  - pub get
  - build runner
  - format, analyze, tests
  - dev flavor APK build

CI is not fully authoritative until real Android/iOS platform projects are committed.

The `/packages/` directory contains source-controlled API contracts and generated clients. Keep it explicitly unignored even though Swift Package Manager ignores `Packages/`.
