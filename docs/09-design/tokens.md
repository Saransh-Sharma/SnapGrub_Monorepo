# Design Tokens

> **Superseded (2026-09):** the source of truth is now the Dart design system in
> `apps/mobile/lib/core/design_system/` — see [design-system-v2.md](design-system-v2.md)
> and the copy guide [voice.md](voice.md). The `packages/design-tokens/*.json` values
> below are legacy and are not used by the app.


Token JSON files live in `packages/design-tokens`:

- `colors.json`
- `spacing.json`
- `typography.json`
- `radii.json`
- `shadows.json`

## Safe Change Rules

- Keep tokens platform-neutral.
- Update Flutter theme usage when token values or names change.
- Avoid one-off colors and spacing in feature screens when a token exists.
- Document breaking token changes in release notes.
