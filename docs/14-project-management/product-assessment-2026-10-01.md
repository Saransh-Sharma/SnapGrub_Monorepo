# SnapGrub: what to improve, refine, and build next

## Context

You asked for an assessment grounded in the code, the docs, and the best apps in the category. I read the Flutter app, the Supabase backend, all numbered docs, and studied ~20 competitors (Cal AI, MacroFactor, MyFitnessPal, Lose It!, Cronometer, SnapCalorie, HealthifyMe, Welling, and others) as of September 2026.

Evidence labels: **[code]** = I or an explorer read it in source; **[docs]** = stated in your docs; **[inferred]** = my reasoning; **(reported)** = competitor fact from a secondary source. Competitor search results are heavily polluted by rival apps' SEO pages, so treat pricing in particular as approximate.

## Verdict

Your own positioning is "the fastest **trustworthy** multimodal food ledger" [docs: Handoff Report line 25]. The app's shell delivers on that: local-first sync, per-item confidence and provenance, an agent that proposes instead of auto-logging, and a no-judgment voice. The engine underneath does not:

- **Typed and spoken meals are not AI.** `conversation_agent.ts:57-81` runs a rule parser first; the model is called only if the parser throws, which happens only when zero of 25 keywords match (`multimodal.ts:345-347`). Unknown words are dropped silently. "Salmon, rice and greens" (your App Store caption) logs rice only. Matching is by substring, so "pineapple" matches "apple". [code]
- **Photo macros are never grounded.** Every item is hard-set to `food_ref_kind: "manual"` (`photo_analysis.ts:376`); calories are whatever the model returns. The catalog holds 30 foods and 3 barcodes. [code]
- **"Fix with a sentence" goes to the same rule parser** (`meal_editor_screen.dart:347`), which cannot understand corrections. [code; outcome inferred]
- **Manual entry has no food search.** `foods-search` exists on the backend and is never called by the app. [code]
- **No accuracy measurement exists**: no golden set, no eval harness. [code]

Fixing this is the highest-leverage work available, and it is also where the market has moved: the apps earning long-term loyalty anchor AI output to a real database (MacroFactor) rather than model-invented numbers.

## Assumptions (flip any of these and the order changes)

1. **India-leaning beachhead**, because the code already is (en-IN fallback, katori/roti units, Indian staples) and home-cooked Indian food is where Western apps are weakest.
2. **Freemium with a per-user AI budget**, not a hard paywall. It fits the trust positioning and bounds cost.
3. **Trust core before retention features.** Reminders that bring people back to wrong numbers accelerate churn.

## Keep (real strengths vs. the field)

- Offline-first outbox with conflict handling; few competitors have this.
- Confidence + provenance in the data model, and propose-then-confirm for the agent (ADR-0011).
- Voice and tone rules enforced by `copy_style_test.dart`; "colors never judge" matches MacroFactor's most-loved trait.
- Sensible plan maths (`plan_calculator.dart`): Mifflin–St Jeor, calorie floors, pace caps.
- Export/delete/retention controls already built.

## Improve: fix what is shipped

| # | Issue | Where | Label |
|---|---|---|---|
| 1 | Text/voice/agent is rule-first, model-last | `_shared/conversation_agent.ts:57`, `_shared/multimodal.ts:514-591`, `analysis-voice-create/index.ts:29` | code |
| 2 | Photo items never matched to catalog | `_shared/photo_analysis.ts:376` | code |
| 3 | Catalog is 30 foods; ingestion script is a stub | `migrations/000010…sql`, `scripts/seed-catalog.sh` | code |
| 4 | Agent meals get server UTC time-of-day on the user's local date (wrong day for IST mornings) | `agent-runs/index.ts:319-330` | code |
| 5 | Update/delete with no title match proposes the day's first meal | `conversation_agent.ts:166-175` | code |
| 6 | Photo analysis queue is in memory; app kill loses the job | `photo_analysis/application/analysis_queue_controller.dart:61` | code |
| 7 | Sex, birth year, height, activity, pace never persisted; goal weight in SharedPreferences only | `onboarding_draft.dart:10-12`, `progress/data/goal_weight_store.dart` | code |
| 8 | `watchAllMeals` is unbounded with one query per meal | `meal_repository.dart:71-82` | code |
| 9 | No JSON schema enforcement or retry on model output; Gemini key in URL query | `photo_analysis.ts:127-132` | code |
| 10 | Feature flags ignored by the new Capture/composer; `photo_analysis` off shows "Photo didn't save" | `capture_controller.dart:126` | code |
| 11 | Alternate app icons wired in Dart/Swift with no plist entries or assets | `appearance_section.dart:123` | code |

## Refine: launch readiness

- **Android release is signed with the debug key** (`android/app/build.gradle.kts:50`). [code]
- **No crash reporting**; `core/logging/` is a placeholder and 7 `catch (_) {}` blocks swallow errors. [code]
- **No funnel analytics.** Only ~9 events fire (`snapstrip_*`, `smart_food_suggestion_*`, `weekly_checkin_*`); none of `onboarding_*`, `meal_saved`, `app_opened` from `docs/api/event-taxonomy.md`. You cannot measure activation or retention. [code]
- **iOS submission risks:** no `PrivacyInfo.xcprivacy`; `image_picker` is used with no `NSPhotoLibraryUsageDescription` (likely rejected at upload; confirm). [code / inferred]
- **AI consent:** `ai_improvement_consent` is stored but read by no function, and photos/text go to Gemini/OpenAI with no disclosure step. Apple guideline 5.1.2(i) on third-party AI likely applies. [code / inferred]
- **Two migrations numbered `000019`.** Check `supabase migration list` before any deploy. [code]
- **Scheduled jobs are not scheduled** (only `infra/supabase/scheduled-jobs.example.sql`), so weekly insights and media cleanup never run. [code]
- **No staging/prod Supabase project; no custom SMTP for OTP.** [code / inferred]
- **AI cost is uncapped per user**; only hourly abuse limits. Meal artwork generation is not cost-logged at all. [code]
- **No Terms/Privacy links, help, or app version in the You tab; no Apple/Google sign-in.** [code]
- **Dead code:** legacy Home/Journal/Barcode/PhotoAnalysis routes, `premium_motion` flag, two coexisting token systems (40 files on the old one). [code]
- **Docs are stale** past July: README, phase status, schema, edge-function list, feature walkthrough (says 6-step onboarding; code has 14). [code vs docs]
- Commit the pending `ios/Flutter/` deletions; the committed `Generated.xcconfig` carries E2E mock defines. [code]

## Build next

**Table stakes you lack (every credible 2026 app has these):**
- Meal reminders / local notifications. Onboarding already collects the choice and says "Reminders are coming soon" (`plan_steps.dart:425`).
- HealthKit + Health Connect (weight in, nutrition out). Google Fit is gone; Health Connect is the only Android path.
- Home-screen widget (remaining calories + capture shortcut).
- Fiber, at minimum; the `fiber_g` column exists and is unused.
- Paywall + purchase SDK.

**Differentiators you are positioned to own:**
1. **Visible honesty.** Confidence and provenance already exist in data. Surface them per item ("from catalog" vs "estimated"), and ask one follow-up only for the uncertain item ("How much oil?"). Published research shows accuracy rises sharply when preparation context is supplied.
2. **A published accuracy number** on home-cooked Indian meals. SnapCalorie turned a 15% error claim into a marketing asset; nobody has one for Indian food.
3. **Adaptive targets** from logged weight + intake. This is MacroFactor's core loyalty driver, and you already have the smoothed weight trend (`weight_trend.dart`). Requires fixing item 7 first.
4. **Personal priors.** Feed `user_food_defaults` into the prompts so the model maps "dal" to *your* dal. Lose It! reports this as its main accuracy gain; you already collect the data and never use it.
5. **Fair paywall.** Cal AI was pulled from the App Store in April 2026 over billing dark patterns; MyFitnessPal paywalled barcode scanning. Free manual/barcode/saved meals plus a transparent price is a real position.
6. **Hinglish and regional-language voice.** Only HealthifyMe serves this, and its reviews complain about coaching quality and refunds (reported).

**Pricing anchor (reported benchmarks):** mass-market AI trackers $30–80/yr, loyalty tools (MacroFactor, Cronometer) $60–72/yr. RevenueCat's 2026 data shows hard paywalls convert ~5× freemium but trials of 17+ days convert far better than 3-day ones. Suggest a 7–14 day trial, a few free AI logs per day, with India priced separately.

## Do not build yet

- Social/community, meal planning/grocery, CGM integrations, coach dashboards.
- More shader/visual-effects work; the polish is already ahead of the substance.
- Expanding AI meal artwork. It is an uncapped image-generation cost per meal with no retention evidence; put it behind the subscription.
- GLP-1 tracking, restaurant menu scan, Apple Watch, recipe import: valuable, but US-weighted and after the core is trustworthy.

## Roadmap

- **Now (≈4 weeks): Trust core + launch blockers.** Items 1–5 and 9 above, food search in manual entry, eval harness, per-user AI budget, crash reporting, funnel events, release signing, privacy manifest + AI disclosure, migration renumber, scheduled jobs, staging project.
- **Next (≈4–10 weeks): Closed beta, then retention + monetisation.** Persist onboarding inputs, reminders, HealthKit/Health Connect, widget, adaptive targets, paywall, personal priors, confidence UI with follow-up questions.
- **Later:** Hinglish voice, published benchmark, GLP-1 support, menu scan, recipe import, Watch, on-device parsing, assistant/MCP access.

## First slice to implement on approval: Trust core

Backend (`services/backend/supabase/functions/`):

1. **Model-first meal parsing.** New `_shared/meal_llm.ts`: one function taking text, locale, cuisine hints, the user's `user_food_defaults`, and an optional base draft; calls Gemini with an enforced `responseSchema`, key in the `x-goog-api-key` header, one schema-repair retry. Returns components plus an `operation` field so the model, not the keyword regex at `conversation_agent.ts:158`, classifies create/update/delete.
2. **Invert the order.** In `conversation_agent.ts:57-81`, `analysis-text-create`, and `analysis-voice-create`, call the model first. Keep `buildDraftFromText` only as an outage fallback, with word-boundary matching, provenance `rule_fallback`, and a warning listing any words it could not match.
3. **Catalog grounding.** Extract the lookup queries from `foods-search/index.ts:25-58` into `_shared/food_lookup.ts`, ranked with `pg_trgm` similarity (already installed) instead of plain `ilike`. New `_shared/catalog_grounding.ts`: for each model item, look up canonical/alias/branded/custom/user-default; on a confident match take per-100 g values from `food_nutrients` × the model's gram estimate and set `food_ref_kind` + `source_id`; otherwise keep the model's numbers, marked as estimated with reduced confidence. Apply to photo (`photo_analysis.ts:376`), text, voice, and agent paths.
4. **Catalog ingestion.** Implement `scripts/seed-catalog.sh` against the existing `canonical_foods` / `food_aliases` / `food_nutrients` / `food_portions` / `catalog_ingest_runs` tables: USDA FoodData Central (public domain) plus an Indian source. IFCT licensing is flagged unresolved in your docs, so that source needs your decision before ingest.
5. **Correction mode.** Add an optional `base_draft` to the text-analysis request in `packages/api-contracts` (contract-first per ADR-0001), regenerate clients; the model receives the structured draft plus the correction and returns the revised draft.
6. **Agent bugs.** `agent-runs/index.ts:319-330`: derive time-of-day in the request's `timezone` and convert to a proper UTC instant. `conversation_agent.ts:174`: remove the `?? rows[0]` fallback; when no meal matches, reply with a clarifying question instead of a proposal.
7. **Cost visibility and budget.** Move the `model_invocations` insert (`analysis-photo-create/index.ts:406`) into a shared helper and log text/agent/artwork calls too. Add a daily per-user cap using the existing `consumeRateLimit` (`_shared/rate_limit.ts`) with a 24 h window.
8. **Eval harness.** New `services/backend/evals/`: 100–150 weighed reference meals (text and photo, weighted to Indian home cooking); a script runs them through the real provider and reports calorie/protein error and item recall. Run on demand before any prompt or model change, not per-PR.

Mobile (`apps/mobile/lib/`):

9. **Food search in manual entry.** Add a search sheet beside `meal_editor/presentation/widgets/custom_food_picker.dart` calling `foods-search` via the generated client; offline it falls back to local custom foods and recents from Drift.
10. **Fix with a sentence.** `meal_editor_screen.dart:335-383` sends the structured draft through the new correction mode; retire `correctionPrompt` (`meal_review_logic.dart:116`).
11. **Provenance chip** on each item in meal review: "Catalog" vs "Estimated".
12. Fix `tool/marketing/captions.json` (em dashes and "beautifully" break `voice.md`).

## Verification

- `npm run check:contracts`; existing backend smoke scripts under `scripts/`; `flutter analyze` and `flutter test` in `apps/mobile`; Maestro `maestro/flows/01_critical_smoke.yaml`.
- New unit tests for `catalog_grounding.ts`, `meal_llm.ts` (mocked provider), and the timezone fix (IST 06:30 lands on the local day). `agent-runs` currently has no tests at all.
- Manual, against the real provider: type "salmon, rice and greens" → three items; "pineapple" → not apple; "actually it was two rotis" on a draft → only that item changes; "delete lunch" with no lunch → a question, not a proposal.
- Eval harness produces a baseline error number before and after grounding.
- To confirm inferred items: upload a build to App Store Connect for the photo-library key and privacy manifest; run `supabase migration list` for the duplicate `000019`.
