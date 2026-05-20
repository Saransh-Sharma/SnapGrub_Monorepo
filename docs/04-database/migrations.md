# Migrations

Migration files live in `services/backend/supabase/migrations`.

## Safe Change Checklist

- Create a new numbered migration; do not edit applied migrations after shared use.
- Add constraints close to the data they protect.
- Add RLS policies in the same phase as the table.
- Add indexes for expected access patterns.
- Update [schema-phase-0-1.md](schema-phase-0-1.md) and [rls.md](rls.md).
- Run:

```sh
npm run backend:lint:migrations
cd services/backend/supabase
supabase db reset
```

## Current Special Cases

- `settings-patch` writes through `public.patch_user_settings`.
- `api_idempotency` stores replay responses for `settings-patch`.
- Private storage buckets exist, but camera/meal upload is not implemented in Phase 1.
