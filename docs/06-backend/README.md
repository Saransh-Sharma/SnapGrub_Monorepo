# Backend

The backend lives in `services/backend/supabase`.

## Setup

```sh
npm ci
cd services/backend/supabase
supabase start
supabase db reset
```

## Checks

```sh
npm run backend:lint:migrations
npm run backend:typecheck
npm run backend:test:rls
```

`backend:test:rls` requires local Supabase URL, anon key, and service-role key exported from `supabase status -o env`.

More detail:

- [edge-functions.md](edge-functions.md)
- [settings-patch-rpc.md](settings-patch-rpc.md)
- [testing.md](testing.md)
