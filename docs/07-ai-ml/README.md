# AI/ML

Phase 4 implements the first AI provider orchestration path for meal photo analysis. This folder documents the active contract, provider security rules, cost knobs, and fallback behavior.

## Current Rules

- No AI provider keys in mobile.
- Backend orchestrates provider calls.
- AI meal analysis is an editable draft, not source of truth.
- Photo analysis supports `AI_PROVIDER=mock|gemini|openai`.
- `AI_PROVIDER` must be set explicitly; use `AI_PROVIDER=mock` locally when provider keys are unavailable.
- Real provider keys, model names, and token price assumptions are backend runtime secrets/config only.
- Meal Editor fields, confidence/provenance fields, and correction-event storage are reused for AI drafts.
- Text, voice, conversation and corrections use the model first (`AI_PROVIDER=gemini|openai`); `mock` uses the offline rule parser. See [ADR-0012](../12-decisions/adr-0012-model-first-parsing-and-catalog-grounding.md).
- Model replies are schema-enforced and then grounded against the catalog. Grounded items carry `food_ref_kind` and a catalog source; the rest stay estimates.
- Model calls are capped per user per day (`AI_DAILY_CALL_LIMIT`, default 100) and logged in `model_invocations`.
- Accuracy is measured with [`services/backend/evals`](../../services/backend/evals/README.md). Run it before changing a prompt or model.

Related:

- [provider-security.md](provider-security.md)
- [future-photo-analysis-contract.md](future-photo-analysis-contract.md)
