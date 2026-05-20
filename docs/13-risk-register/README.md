# Risk Register

| ID | Risk | Owner | Probability | Impact | Mitigation | Status |
| --- | --- | --- | --- | --- | --- | --- |
| R-001 | Flutter, Dart, Supabase CLI, or Deno missing locally/CI | Engineering | High | High | Document required toolchain and gate Phase 2 on full command pass | Open |
| R-002 | Native Flutter Android/iOS platform folders are not committed | Mobile | High | High | Generate real platform projects with dev/staging/prod flavors before Phase 2 | Open |
| R-003 | RLS regression exposes cross-user data | Backend | Medium | Critical | Keep RLS harness in CI and add tests for every user-owned table | Open |
| R-004 | API contract drift between mobile and backend | Full stack | Medium | High | Use OpenAPI as source of truth and enforce generated client freshness | Open |
| R-005 | Offline settings replay creates duplicate or conflicting server state | Full stack | Medium | High | Preserve `client_request_id`, use idempotency table, test replay/conflict cases | Open |
| R-006 | Future AI provider cost or secret exposure | AI/backend | Medium | High | Backend-only provider calls, document cost/rate limits/fallbacks before release | Open |

## Maintenance

Update this register whenever a phase adds new infrastructure, data flows, third-party providers, privacy exposure, or release blockers.
