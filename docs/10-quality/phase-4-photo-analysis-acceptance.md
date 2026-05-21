# Phase 4 Photo Analysis Acceptance

Use this checklist before Phase 5 barcode/OCR/text/voice work.

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

- Camera permission grant, deny, background, and foreground states behave correctly.
- Capture creates a local compressed image asset immediately.
- Uploaded originals and thumbnails are under the authenticated user storage prefix.
- Analysis failure preserves the image and offers retry/manual fallback.
- Completed analysis opens Meal Editor as an unsaved editable photo draft.
- Low-confidence rows are highlighted and warning text is visible.
- Edited AI drafts save as `source=photo` with `analysis_job_id` and `photo_asset_id`.
- Forged analysis or asset IDs fail server-side.
- No EXIF location metadata is uploaded after mobile compression.

## Photo QA Set

Indian thali, roti + sabzi, dal chawal, biryani, salad, packaged snack, soup/liquid, dark image, blurry image, multiple plates, and non-food photo.
