# SnapGrub Design System v2 — "Porcelain & Metal"

Source of truth lives in Dart. Import everything with:

```dart
import 'package:snapgrub/core/design_system/design_system.dart';
```

## Principles (review checklist)
1. **One hero number per screen**, tabular figures (`context.sg.heroNumber` / `metric` / `metricSmall`).
2. **Fixed macro colours** — energy = sage, protein = persimmon, carbs = gold, fat = slate. Always via `context.sg.macro(Macro.x)`.
3. **Adherence-neutral** — never red / error colour for "over target"; use `context.sg.overTarget`. Streaks count days *logged*.
4. **AI never blocks** — background work shows a pending card, never a blocking spinner screen.
5. **Everything is undoable** — destructive actions use `showUndoSnackBar` (deferred commit) or `confirmDestructive` / `HoldToConfirmButton`.
6. **Delight has a budget** — `Celebration.play` is rate-limited; metal/foil only on earned moments (capture button, hero ring bezel, medals, plan card).
7. **Every effect has a fallback** — all effect widgets degrade automatically via `SgEffectsScope` (Reduce Motion, Low Power, user setting, shader failure).

## Tokens
| Need | Use |
|---|---|
| Colours | `Theme.of(context).colorScheme` for Material roles; `context.sg` for macro, semantic (`success`/`warning`/`info`), `hero`/`onHero`, `outlineStrong`, `overTarget` |
| Spacing | `SnapGrubDesignTokens.space4 … space40` (4/8/12/16/20/24/32/40) |
| Radii | `radiusXs 12`, `radiusSm 18`, `radiusMd 24`, `radiusLg 32`, `radiusPill` |
| Elevation | `context.sg.elevation1/2/3` |
| Type | Geist (UI) + Instrument Serif (display/headline, editorial). `context.sg.editorial` for serif italic accents |
| Motion | `SgMotion.of(context)` (reduce-motion aware durations/curves, `stagger(i)`), `SgSprings` |
| Haptics | `SgHaptics.tap/tick/shutter/detect/logged/milestone/warn/impact` — never call `HapticFeedback` directly |

## Components (`lib/core/design_system/components`)
- `SgCard(variant: flat|raised|hero|glass|metalRim, onTap:)`, `SgSectionHeader`
- `SgRing(progress, color, liquid:, bezel:)` — spring-animated, overflow lap, liquid shader
- `RollingNumber(value, style)` — odometer digits
- `MacroChips`, `MacroBar`, `MacroLegend`
- `WeekStrip`, `SgTabBar`, `CaptureButton`
- Inputs: `SgNumberField` (owns its controller), `SgStepper`, `SgWheelPicker`, `SgRulerPicker`, `SgKeypad`
- Sheets: `showSgSheet`, `SgSheetScaffold`, `SgSheetAction`, `confirmDestructive`
- States: `EmptyState`, `ErrorState` (uses `friendlyError`), `InlineError`, `SgIllustration`, `SgSkeleton`, `SgMealCardSkeleton`
- `StatusPill`, `HoldToConfirmButton`, `SgEntrance` (staggered entrance), `Celebration.play`
- Existing: `PremiumPressable` (spring press + haptic + focus), `PremiumGlassSurface`, `PremiumBackdrop`, `SnapGrubMark`, `MealArtwork`

## Effects (`lib/core/design_system/effects`, shaders in `apps/mobile/shaders`)
| Widget | Shader | Use |
|---|---|---|
| `MetalSurface(metal:, shape: planar/disc/ring)` | `metal_sheen.frag` | medals, shutter, bezels, streak badge |
| `HoloFoil(child:)` | `holo_foil.frag` | plan card, 100-day streak, recap cover |
| `SgRing(liquid: true)` | `liquid_ring.frag` | calorie hero + macro rings |
| `SgRipple(controller:)` | `ripple.frag` | shutter, meal landed |
| `ScanBeam(child:)` | `scan_beam.frag` | photo under analysis |
| `DissolveTransition(progress:)` | `dissolve.frag` | swipe delete (reverse = undo) |
| `MeshAurora()` | `mesh_aurora.frag` | time-of-day backdrops |
| `LiquidGlass(child:)` | `liquid_glass.frag` | tab bar / floating chrome |

Shaders are preloaded at boot (`ShaderLibrary.preloadAll`). Tilt comes from `TiltBuilder` (accelerometer, ref-counted, paused off-screen). Quality tiers: `SgEffectsScope.of(context)` → `full` / `reduced` / `off`.

## Feedback (`lib/core/feedback`)
- `friendlyError(error)` → title/message/retryable/offline. **Never** render `error.toString()`.
- `Labels.*` → human labels for enums, provenance, sync state, dates (`Labels.when`, `Labels.day`, `Labels.relative`). **Never** render `.name` of an enum.
- `showUndoSnackBar`, `showSgToast`.

## Navigation
- Tabs via `StatefulShellRoute`: Today `/home`, Progress `/progress`, Atlas `/atlas`, You `/settings`; center capture → `/capture`.
- Drill-ins: `context.push(...)` (or `context.open`). Chained flows (capture → review): `context.continueTo(...)`. Finish: `context.popOrGo('/home')` (`lib/app/router/nav.dart`).
- Tab screens must add `AppShell.bottomInset(context)` bottom padding to scrollables so content clears the floating tab bar.
