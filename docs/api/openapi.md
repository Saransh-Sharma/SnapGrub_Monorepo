# API Contracts

The canonical contract is `packages/api-contracts/openapi.yaml`.

Phase 0-1 paths:

- `POST /profile-bootstrap`
- `PATCH /settings-patch`
- `POST /events-ingest`

These names intentionally match Supabase Edge Function deploy names. A future API gateway can expose `/v1/...` friendly paths without changing the Phase 0-1 mobile integration boundary.

Run:

```sh
npm run validate:openapi
```
