# AI/ML

AI/ML is not implemented in Phase 0/1. This folder documents guardrails that Phase 2+ work must follow.

## Current Rules

- No AI provider keys in mobile.
- Backend orchestrates provider calls.
- AI meal analysis is an editable draft, not source of truth.
- Confidence, provenance, and correction-event tracking must be preserved.
- Cost, fallback, and prompt contracts must be documented before provider integration ships.

Related:

- [provider-security.md](provider-security.md)
- [future-photo-analysis-contract.md](future-photo-analysis-contract.md)
