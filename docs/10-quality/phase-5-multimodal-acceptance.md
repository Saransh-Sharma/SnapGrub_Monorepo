# Phase 5 Multimodal Acceptance

## Automated

- `npm run check:contracts`
- `npm run backend:typecheck`
- `npm run backend:test:phase5`
- `flutter analyze`
- `flutter test`

## Manual

- Barcode permission/camera flow opens from Home and returns a packaged-food draft when a known barcode resolves.
- Barcode misses offer OCR/manual fallback without losing context.
- OCR label assist parses label text into editable calories/macros and keeps confidence/provenance visible.
- Text entry accepts a natural-language meal and opens the unified Meal Editor draft.
- Voice entry handles microphone permission denial and edited transcript submission.
- Every Phase 5 draft can be edited before save and then persists as a normal local-first meal.
- No provider key or service-role value is present in mobile env/config.
