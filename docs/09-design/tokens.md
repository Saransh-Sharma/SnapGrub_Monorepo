# Design Tokens

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
