# Photo Analysis Contract

Phase 4 implements the first photo analysis loop through Supabase Edge Functions:

- `POST /analysis-photo-create`
- `GET /analysis-get/{analysis_id}`

The canonical wire shape is in [../../packages/api-contracts/openapi.yaml](../../packages/api-contracts/openapi.yaml).

## Required Semantics

- AI output must be an editable meal draft.
- Store confidence by relevant item/nutrition estimate.
- Preserve provenance: image source, model/provider/version, prompt contract version, and analysis timestamp.
- Record user corrections so the system can distinguish accepted AI output from edited truth.
- Support fallback states for provider timeout, low confidence, unsupported image, and user cancellation.

## Provider Configuration

- `AI_PROVIDER=mock|gemini|openai`
- `GEMINI_API_KEY`
- `GEMINI_PRIMARY_MODEL`
- `OPENAI_API_KEY`
- `OPENAI_FALLBACK_MODEL`
- `AI_INPUT_PRICE_PER_1M`
- `AI_OUTPUT_PRICE_PER_1M`

Provider keys stay in backend environments only. Mobile uploads user-owned images to private Supabase Storage and calls SnapGrub Edge Functions.
