# API Contracts

`packages/api-contracts/openapi.yaml` is the source of truth for frontend/backend integration. Generated Dart and TypeScript clients are committed and must stay fresh.

## Commands

```sh
npm run check:contracts
bash scripts/generate-api-clients.sh
```

`npm run check:contracts` validates OpenAPI and fails if generated clients differ from committed output.

## Current Callable API

Phase 0/1 uses Supabase Edge Function deploy names as the API paths:

- `POST /profile-bootstrap`
- `PATCH /settings-patch`
- `POST /events-ingest`

Friendly `/v1/...` gateway paths can be introduced later behind a gateway, but the current mobile integration uses the function names.

Related:

- [endpoints.md](endpoints.md)
- [errors.md](errors.md)
- [examples.md](examples.md)
- [../api/openapi.md](../api/openapi.md)
