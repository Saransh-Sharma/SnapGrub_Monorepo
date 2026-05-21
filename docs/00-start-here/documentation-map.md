# Documentation Map

The numbered folders are the canonical developer docs. Older folders remain available for compatibility.

| Area | Canonical folder | What belongs here |
| --- | --- | --- |
| Getting started | `00-start-here` | New developer paths, doc ownership, current gate links |
| Product | `01-product` | MVP boundaries, phase scope, handoff references |
| Architecture | `02-architecture` | System shape, mobile/backend architecture, security boundaries |
| API | `03-api-contracts` | OpenAPI workflow, endpoints, errors, examples |
| Database | `04-database` | Supabase schema, migrations, RLS, indexes |
| Frontend | `05-frontend` | Flutter setup, feature architecture, local-first behavior |
| Backend | `06-backend` | Supabase setup, Edge Functions, RPCs, backend tests |
| AI/ML | `07-ai-ml` | Provider rules, prompt/analysis contracts, cost/fallback notes |
| Nutrition catalog | `08-nutrition-catalog` | Source, licensing, provenance, ingestion rules |
| Design | `09-design` | Tokens, UX decisions, design-system guidance |
| Quality | `10-quality` | Test strategy, manual QA, release gates |
| Operations | `11-operations` | Local ops, CI/CD, runbooks |
| Decisions | `12-decisions` | ADRs and decision process |
| Risks | `13-risk-register` | Active risks with owner, probability, impact, mitigation |
| Project management | `14-project-management` | Phase status, readiness, release notes |

## How To Change Docs Safely

For each implementation phase, review changed migrations, OpenAPI, Edge Functions, Flutter modules, scripts, and CI files. Update the matching numbered docs first, then update compatibility docs only when needed.

Important architecture choices belong in ADRs under [../12-decisions/README.md](../12-decisions/README.md), not buried inside feature docs.

Implementation PRs must update docs in the same PR when they change API shape, database schema/RLS, setup commands, feature behavior, test gates, operational risk, or release status.
