# Risk Register

| ID | Risk | Owner | Probability | Impact | Mitigation | Status |
| --- | --- | --- | --- | --- | --- | --- |
| R-001 | Flutter, Dart, Supabase CLI, or Deno missing locally/CI | Engineering | High | High | Document required toolchain and gate Phase 4 acceptance on full command pass | Open |
| R-002 | Native Flutter Android/iOS platform folders are not committed | Mobile | High | High | Generate real platform projects with dev/staging/prod flavors before mobile device QA | Open |
| R-003 | RLS regression exposes cross-user data | Backend | Medium | Critical | Keep RLS harness in CI and add tests for every user-owned table | Open |
| R-004 | API contract drift between mobile and backend | Full stack | Medium | High | Use OpenAPI as source of truth and enforce generated client freshness | Open |
| R-005 | Offline replay creates duplicate or conflicting server state | Full stack | Medium | High | Preserve `client_request_id`, use idempotency/revision checks where available, test replay/conflict cases | Open |
| R-006 | AI provider cost, outage, schema drift, or secret exposure | AI/backend | Medium | High | Backend-only provider calls, `AI_PROVIDER=mock` local fallback, env-configured models/prices, model invocation logs, and no provider keys in mobile | Open |
| R-007 | Phase 3 template/custom-food direct table sync bypasses server validation | Full stack | Medium | Medium | Keep RLS strict, validate locally, add Edge Function later if cross-table validation is needed | Open |
| R-008 | `/packages/` ignored by Swift `Packages/` rule hides contracts | Engineering | Medium | High | Keep `/packages/` explicitly unignored and ensure contract checks run in CI | Mitigated |
| R-009 | Meal timezone rollup day is computed inconsistently | Backend/mobile | Medium | High | Use stored meal timezone, test boundary cases, keep rollup logic centralized | Open |
| R-010 | Generated Drift/API artifacts become stale | Mobile/full stack | Medium | High | Run build runner and `npm run check:contracts` after schema/contract changes | Open |
| R-011 | Phase 4 photo analysis is implemented but not fully verified locally | Full stack | High | High | Install Deno/Flutter/Supabase CLI, generate native platform projects, run Phase 4 acceptance, and test real provider configuration in staging | Open |

## Maintenance

Update this register whenever a phase adds new infrastructure, data flows, third-party providers, privacy exposure, or release blockers.
