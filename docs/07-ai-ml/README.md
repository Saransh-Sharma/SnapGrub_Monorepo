# AI/ML

Phase 4 implements the first AI provider orchestration path for meal photo analysis. This folder documents the active contract, provider security rules, cost knobs, and fallback behavior.

## Current Rules

- No AI provider keys in mobile.
- Backend orchestrates provider calls.
- AI meal analysis is an editable draft, not source of truth.
- Photo analysis supports `AI_PROVIDER=mock|gemini|openai`.
- `AI_PROVIDER=mock` is the local fallback when provider keys are unavailable.
- Real provider keys, model names, and token price assumptions are backend runtime secrets/config only.
- Meal Editor fields, confidence/provenance fields, and correction-event storage are reused for AI drafts.

Related:

- [provider-security.md](provider-security.md)
- [future-photo-analysis-contract.md](future-photo-analysis-contract.md)
