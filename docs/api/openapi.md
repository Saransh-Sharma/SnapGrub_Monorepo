# API Contracts

The canonical contract is `packages/api-contracts/openapi.yaml`. This legacy compatibility page points to the current numbered API docs.

Current Phase 0-8 paths include:

- `POST /profile-bootstrap`
- `PATCH /settings-patch`
- `POST /events-ingest`
- `GET /meals`
- `GET /meals/{meal_id}`
- `POST /meals`
- `PATCH /meals/{meal_id}`
- `DELETE /meals/{meal_id}`
- `POST /analysis-photo-create`
- `GET /analysis-get/{analysis_id}`
- `POST /barcode-resolve`
- `POST /foods-search`
- `POST /analysis-text-create`
- `POST /analysis-label-create`
- `POST /analysis-voice-create`
- `POST /exports-create`
- `GET /exports-create/{export_request_id}`
- `POST /account-delete`
- `POST /media-retention-cleanup`
- `POST /weekly-insights-generate`

Phase 8 privacy endpoints are documented in [../03-api-contracts/endpoints.md](../03-api-contracts/endpoints.md). The deploy names intentionally match Supabase Edge Function names. A future API gateway can expose `/v1/...` friendly paths without changing the current mobile integration boundary.

Run:

```sh
npm run validate:openapi
npm run check:contracts
```
