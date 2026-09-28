# Conversational redesign delivery checklist

## Implemented

- [x] Premium light/dark tokens, Instrument Serif, motion tokens, haptics, glass,
      and two Impeller fragment effects with accessibility fallbacks.
- [x] Additive Supabase and Drift models for threads, messages, runs, proposals,
      and meal visuals.
- [x] Conversation-first `/home`, local-date pager, date jump, synthetic meal
      events, composer, streaming states, recovery copy, and review cards.
- [x] Local-first proposal confirmation through the existing meal repository.
- [x] Offline queue/replay for chat and proposal acknowledgements.
- [x] Private generated-art function, local cache, deterministic fallback art,
      atlas mosaic, pinch/catalog entry, and meal shared-element return.
- [x] Generated contract types and API paths.
- [x] Export/account-deletion coverage for conversations and generated assets.
- [x] Compatibility `/home-legacy` route and independently named feature flags.
- [x] OCR plugin updated to the current compatible Flutter release.

## Verification evidence

Evidence is recorded after each gate instead of inferred from implementation.

- [x] Flutter dependency resolution
- [x] Dart formatting and static analysis
- [x] Flutter unit/widget tests (71 passing)
- [x] OpenAPI validation and generated-client freshness
- [x] Edge Function typecheck and conversation-agent unit tests
- [x] Migration lint
- [x] Warning-free arm64 iOS simulator build
- [x] iPhone 17 Pro / iOS 26.5 conversational critical flow
- [x] Dedicated iPhone 17 Pro / iOS 26.5 major-state screenshots

The production-style mock flow was last verified on 28 July 2026 in a dedicated
`SnapGrub QA` simulator. It covers password authentication, onboarding, text
meal parsing, proposal confirmation, day paging, atlas navigation, the capture
tray, manual editing, settings, and deterministic return navigation. Final
captures are stored alongside the earlier proposal evidence as
`04-verified-day-thread.png` and `05-verified-meal-atlas.png`.

## Physical-device gates

These require attached hardware and remain release gates: ProMotion/oldest-device
frame pacing, real camera and microphone behavior, haptics, thermal behavior,
memory pressure, and bounded image-cache observation in profile release mode.
