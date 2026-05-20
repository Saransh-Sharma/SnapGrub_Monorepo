# Backend Architecture

Supabase is the Phase 0-1 backend.

- Migrations live in `services/backend/supabase/migrations`.
- RLS policies are applied with each table migration.
- Edge Functions expose application APIs for bootstrap, settings, and analytics.
- Feature flag overrides are resolved server-side.
- Service-role keys are used only inside Supabase/Vercel server environments.
