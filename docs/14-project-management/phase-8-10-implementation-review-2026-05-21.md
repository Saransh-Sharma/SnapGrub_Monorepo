# Phase 8-10 Implementation Review - 2026-05-21

This is the canonical current-state review for the Phase 8 implementation pass and the Phase 9/10 release-readiness groundwork.

## Status Labels

- `implemented`: source exists and is wired into app/backend paths.
- `verified locally`: automated local checks passed in this environment.
- `source-level only`: source exists but still needs mobile/device/manual acceptance.
- `staging required`: cannot be completed without staging secrets, deployed schedules, dashboards, or release infrastructure.
- `blocked`: local environment lacks a required tool.

## Verification Snapshot

Passed on 2026-05-21 after applying Phase 8 source:

- `npm run check:contracts`
- `npm run backend:typecheck`
- `npm run backend:lint:migrations`
- `supabase db reset`
- `npm run backend:test:auth-profile`
- `npm run backend:test:rls`
- `npm run backend:test:meal-core`
- `npm run backend:test:photo-analysis`
- `npm run backend:test:multimodal`
- `npm run backend:test:offline-sync`
- `npm run backend:test:insights`
- `npm run backend:test:privacy`

Blocked in the current local shell:

- `flutter analyze`, `flutter test`, and mobile builds because `flutter` and `dart` are not on `PATH`.
- Device manual acceptance because it requires an iOS simulator/device and Android emulator/device.

## Phase Review

| Phase | Current state | Evidence | Remaining gap |
| --- | --- | --- | --- |
| Phase 8 backend | verified locally | Migration `000013_phase8_privacy_export_delete.sql`; `exports-create`, `account-delete`, and `media-retention-cleanup`; OpenAPI Phase 0-8 contracts; privacy smoke | Staging deployment, scheduled cleanup, production data-retention review |
| Phase 8 mobile | source-level only | Privacy routes/screens under `features/privacy`, Settings entry point, AI/media toggles through `settings-patch`, export request UI, delete-account and clear-local flows | Flutter analyze/tests/build, iOS/Android manual acceptance, signed URL download UX validation |
| Phase 9 observability | source-level docs/gates | `docs/11-operations/beta-observability.md`, Phase 8 CI smoke gate, rate-limit helper RPC | Real dashboards, alerts, synthetic staging failure tests, crash reporting provider decision/config |
| Phase 10 release candidate | documented gate | Release checklist and phase status now identify privacy/export/delete and observability blockers | Store/TestFlight/Internal Testing artifacts, prod deploy, staged rollout monitoring |

## Implemented Phase 8 Behavior

- `exports-create` now creates private export artifacts rather than only enqueueing requests.
- Export artifacts are stored in `exports-private` under the authenticated user prefix.
- Supported export types are `nutrition_json` and `journal_csv`.
- Completed export rows include storage bucket/path, content type, size, row counts, artifact expiry, signed URL, and signed URL expiry.
- `GET /exports-create/{export_request_id}` refreshes the signed URL for an owned completed export.
- `account-delete` requires the authenticated user to send `confirmation: "DELETE"` and then deletes user-owned storage plus the Supabase Auth user.
- `account_deletion_requests` records processing/completed/failed status and storage deletion counts.
- `media-retention-cleanup` is a service-role endpoint for expired export artifacts and expired retained meal media.
- `weekly-insights-generate` can run for one user or batch users due for a week, enabling scheduled staging/prod invocation.
- `api_rate_limits` and `consume_api_rate_limit` protect expensive/destructive export and deletion paths.

## Remaining External Gates

1. Put Flutter/Dart on `PATH`, regenerate if needed, then run mobile analyze/tests/build.
2. Run iOS/Android manual acceptance for privacy toggles, export, delete account, clear local data, and existing Phase 0-7 flows.
3. Deploy staging Supabase migrations/functions and configure real Gemini/OpenAI secrets server-side only.
4. Configure staging schedules for weekly insights and media-retention cleanup, then observe successful runs.
5. Configure dashboards/alerts and run synthetic beta observability tests.
6. Produce release-candidate mobile builds only after Phase 8 device QA and Phase 9 staging observability pass.
