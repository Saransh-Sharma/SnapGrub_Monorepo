# Security Boundaries

SnapGrub separates public mobile configuration from protected backend authority.

## Mobile

- Allowed: Supabase URL and anon key.
- Forbidden: Supabase service-role key, AI provider keys, private storage credentials, provider billing secrets.
- Local data must be filtered by authenticated `userId`.

## Backend

- Edge Functions may use service-role credentials when needed.
- RLS remains the primary protection for user-owned tables.
- Function responses must not return service-only fields.
- Feature flag overrides are resolved server-side and not directly readable by clients.

## AI/ML

Future AI provider calls must run through backend orchestration. The mobile app may upload or reference user media only through approved backend/storage flows and must treat AI output as an editable draft.

Related ADR: [../12-decisions/ADR-0004-service-role-and-ai-keys-backend-only.md](../12-decisions/ADR-0004-service-role-and-ai-keys-backend-only.md)
