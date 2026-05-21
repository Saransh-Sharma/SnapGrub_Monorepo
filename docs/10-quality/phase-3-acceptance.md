# Phase 3 Acceptance

Use this checklist before starting Phase 4 AI/photo/barcode/OCR/voice work.

## Automated

- `npm run check:contracts`
- `npm run backend:lint:migrations`
- `npm run backend:typecheck`
- `supabase db reset`
- `npm run backend:test:rls`
- `npm run backend:test:meal-core`
- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `flutter analyze`
- `flutter test`

## Manual

- Manual meal create/update/delete works offline and syncs later.
- Daily rollup updates locally and after server sync.
- Correction events are returned by backend and cached locally.
- Templates can be saved, listed, used, and deleted.
- Custom foods can be created, listed, inserted into meal drafts, and deleted.
- SnapStrip action flags disable photo/barcode/text/voice controls.

## Known Environment Requirements

Flutter, Dart, Supabase CLI, Deno, Node 20, and local Supabase env keys must be installed/exported before this checklist is authoritative.
