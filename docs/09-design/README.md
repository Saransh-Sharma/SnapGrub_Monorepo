# Design

> **Superseded (2026-09):** the source of truth is now the Dart design system in
> `apps/mobile/lib/core/design_system/` — see [design-system-v2.md](design-system-v2.md)
> and the copy guide [voice.md](voice.md). The `packages/design-tokens/*.json` values
> below are legacy and are not used by the app.


Design documentation covers reusable tokens, UX decisions, and implementation constraints.

Current design token files live under `packages/design-tokens`.

## Current UX Surfaces

- Onboarding: fast profile/goal setup with offline save.
- Home: SnapStrip shell, progress summary, recent meals, and quick actions.
- Meal Editor: source-of-truth edit surface for meal title, type, time, items, quantities, macros, confidence/provenance, templates, and custom foods.
- Journal and Progress: scan-friendly daily meal history and local rollup summaries.
- Templates and Custom Foods: utility screens for repeated meals and user-owned foods.

SnapStrip photo/barcode/text/voice actions must reflect feature flags with disabled controls when a rollout is off.

More detail:

- [tokens.md](tokens.md)
- [onboarding-ux.md](onboarding-ux.md)
