# Risk Register

| ID | Risk | Owner | Probability | Impact | Mitigation | Status |
| --- | --- | --- | --- | --- | --- | --- |
| R-001 | JDK missing locally/CI blocks Android Gradle builds | Engineering | High | High | Install a JDK locally and in CI, then require `flutter build apk --debug --flavor dev --dart-define=SNAPGRUB_ENV=dev` | Open |
| R-002 | Native Flutter Android/iOS project configuration can drift from flavor/bundle expectations | Mobile | Medium | High | Keep `scripts/bootstrap-mobile-platforms.sh` checking concrete Gradle/Xcode files and run device QA for dev/staging/prod identifiers | Open |
| R-003 | RLS regression exposes cross-user data | Backend | Medium | Critical | Keep RLS harness in CI and add tests for every user-owned table | Open |
| R-004 | API contract drift between mobile and backend | Full stack | Medium | High | Use OpenAPI as source of truth and enforce generated client freshness | Open |
| R-005 | Offline replay creates duplicate or conflicting server state | Full stack | Medium | High | Preserve `client_request_id`, use idempotency/revision checks where available, test replay/conflict cases | Open |
| R-006 | AI provider cost, outage, schema drift, or secret exposure | AI/backend | Medium | High | Backend-only provider calls, `AI_PROVIDER=mock` local fallback, env-configured models/prices, model invocation logs, and no provider keys in mobile | Open |
| R-007 | Phase 3 template/custom-food direct table sync bypasses server validation | Full stack | Medium | Medium | Keep RLS strict, validate locally, add Edge Function later if cross-table validation is needed | Open |
| R-008 | `/packages/` ignored by Swift `Packages/` rule hides contracts | Engineering | Medium | High | Keep `/packages/` explicitly unignored and ensure contract checks run in CI | Mitigated |
| R-009 | Meal timezone rollup day is computed inconsistently | Backend/mobile | Medium | High | Use stored meal timezone, test boundary cases, keep rollup logic centralized | Open |
| R-010 | Generated Drift/API artifacts become stale | Mobile/full stack | Medium | High | Run build runner and `npm run check:contracts` after schema/contract changes; keep generated Drift code committed | Open |
| R-011 | Phase 4 photo analysis mobile acceptance is not fully verified on devices | Full stack | Medium | High | Backend mock smoke is now covered; run device camera/upload/retry acceptance and real provider staging validation | Open |
| R-012 | CI or local Node 20 Supabase tests fail without WebSocket support | Engineering | Medium | Medium | Keep `NODE_OPTIONS=--experimental-websocket` on backend integration test steps until Node runtime moves to native support | Mitigated |
| R-013 | Phase 7 weekly insight generation path is verified manually but not scheduled operationally | Backend/ops | Medium | Medium | Add staging cron/scheduled generation validation before enabling the flag broadly | Open |
| R-014 | Phase 6 export implementation is misunderstood as full artifact generation | Product/backend | Medium | Medium | Document `exports-create` as enqueue only and keep artifact/account-deletion work in Phase 8+ scope | Mitigated |

## Maintenance

Update this register whenever a phase adds new infrastructure, data flows, third-party providers, privacy exposure, or release blockers.
