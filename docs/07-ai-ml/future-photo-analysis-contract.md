# Future Photo Analysis Contract

This is a Phase 2+ guardrail, not an implemented contract.

## Required Semantics

- AI output must be an editable meal draft.
- Store confidence by relevant item/nutrition estimate.
- Preserve provenance: image source, model/provider/version, prompt contract version, and analysis timestamp.
- Record user corrections so the system can distinguish accepted AI output from edited truth.
- Support fallback states for provider timeout, low confidence, unsupported image, and user cancellation.

Before implementation, define the OpenAPI path, DB migrations, storage access model, and QA cases.
