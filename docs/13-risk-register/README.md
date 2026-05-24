# Risk Register

| ID | Risk | Owner | Probability | Impact | Mitigation | Status |
| --- | --- | --- | --- | --- | --- | --- |
| R-001 | Flutter/Dart missing locally blocks mobile analyze/test/build | Engineering | High | High | Install Flutter/Dart or add them to `PATH`; require analyze/test/build before Phase 9 entry | Open |
| R-002 | Native Flutter Android/iOS project configuration can drift from flavor/bundle expectations | Mobile | Medium | High | Keep `scripts/bootstrap-mobile-platforms.sh` checking concrete Gradle/Xcode files and run device QA for dev/staging/prod identifiers | Open |
| R-003 | RLS regression exposes cross-user data | Backend | Medium | Critical | Keep RLS harness in CI and add tests for every user-owned table | Open |
| R-004 | API contract drift between mobile and backend | Full stack | Medium | High | Use OpenAPI as source of truth and enforce generated client freshness | Open |
| R-005 | Offline replay creates duplicate or conflicting server state | Full stack | Medium | High | Preserve `client_request_id`, use idempotency/revision checks where available, test replay/conflict cases | Open |
| R-006 | AI provider cost, outage, schema drift, or secret exposure | AI/backend | Medium | High | Backend-only provider calls, explicit `AI_PROVIDER` config, env-configured models/prices, model invocation logs, and no provider keys in mobile | Open |
| R-007 | Phase 3 template/custom-food direct table sync bypasses server validation | Full stack | Medium | Medium | Keep RLS strict, validate locally, add Edge Function later if cross-table validation becomes necessary | Open |
| R-008 | `/packages/` ignored by Swift `Packages/` rule hides contracts | Engineering | Medium | High | Keep `/packages/` explicitly unignored and ensure contract checks run in CI | Mitigated |
| R-009 | Meal timezone rollup day is computed inconsistently | Backend/mobile | Medium | High | Use stored meal timezone, test boundary cases, keep rollup logic centralized | Open |
| R-010 | Generated Drift/API artifacts become stale | Mobile/full stack | Medium | High | Run build runner and `npm run check:contracts` after schema/contract changes; keep generated Drift code committed | Open |
| R-011 | Photo analysis mobile acceptance is not fully verified on devices | Full stack | Medium | High | Backend mock smoke is covered; run device camera/upload/retry acceptance and real provider staging validation | Open |
| R-012 | CI or local Node 20 Supabase tests fail without WebSocket support | Engineering | Medium | Medium | Keep `NODE_OPTIONS=--experimental-websocket` on backend integration test steps until Node runtime moves to native support | Mitigated |
| R-013 | Weekly insight generation can remain source-only if schedules are not validated | Backend/ops | Medium | Medium | Use batch `weekly-insights-generate`, configure staging schedule, observe one successful run before enabling production | Open |
| R-014 | Phase 6 export enqueue is mistaken for Phase 8 artifact generation | Product/backend | Low | Medium | Phase 8 docs now state `exports-create` generates artifacts; keep release notes and API docs current | Mitigated |
| R-015 | Destructive account deletion removes data unexpectedly or partially fails | Backend/mobile | Medium | Critical | Require exact `DELETE`, keep audit rows, run Phase 8 smoke, device QA, and staging deletion tests with storage objects | Open |
| R-016 | Signed export URLs leak or live too long | Backend/security | Medium | High | Keep exports in private bucket, use short-lived signed URLs, refresh only after ownership check, clean expired artifacts | Open |
| R-017 | Cleanup jobs delete the wrong media or fail silently | Backend/ops | Medium | High | Use service-role-only cleanup, bounded limits, helper RPCs, staging synthetic tests, and missed-job alerts | Open |
| R-018 | Phase 9 observability is documented but not actually wired in staging | Ops/full stack | Medium | High | Require dashboards, alerts, synthetic failures, and crash reporting before Phase 10 release candidate | Open |

## Maintenance

Update this register whenever a phase adds new infrastructure, data flows, third-party providers, privacy exposure, or release blockers.
