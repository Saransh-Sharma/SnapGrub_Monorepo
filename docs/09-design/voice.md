# SnapGrub voice & copy

**Warm but terse.** Confident and friendly, never cute in errors. Celebrate briefly. Never lecture, never judge what someone ate.

Benchmarks: Cal AI, Yazio, Headspace for tone; MyFitnessPal and Lose It! for literal navigation; Apple HIG for alerts and permissions; Duolingo for streak language; MacroFactor for trend-weight language.

| Do | Don't |
|---|---|
| "120 kcal over" | "You exceeded your goal by 120 kcal!" / "A generous day." |
| "You're offline. Anything you log is saved and will sync later." | "Couldn't reach the kitchen…" / "Error: SocketException" |
| "Code expired. Get a new one." | "Couldn't complete that request." |
| "7-day streak" · "7 days in a row!" | "You broke your streak." |
| "Photo estimate · High confidence" | "Confidence: 62% photo_ai" |
| "Thinking…" | "Thinking with you…" |
| "Last 7 days" | "Your last 7 days, gently summarised." |

## Length budgets

| Element | Max |
|---|---|
| Screen or sheet title | 4 words, sentence case, no period |
| Body / subtitle | 1 sentence, aim for ≤ 12 words |
| Button | 1–3 words, starts with a verb (except "Done", "Got it") |
| Error | Title ≤ 4 words + body ≤ 12 words: what happened, then what to do |
| Empty state | Title + ≤ 10-word body + verb button |
| Toast / snackbar | ≤ 6 words + optional one-word action ("Undo") |
| Onboarding "why" line | ≤ 10 words |

## Rules

- Lead with what happened, then what to do. One sentence each.
- Alerts: the title is the question ("Delete this meal?"), and the buttons are verbs ("Delete meal" / "Keep it").
- Empty states invite an action ("Snap your first meal").
- Never use red or alarm language for eating more than a target. State numbers, not verdicts.
- Exclamation marks only for milestones, streaks, goal reached and the weekly recap.
- The assistant says "I" only inside chat bubbles. Elsewhere, use no pronoun or a sparing "we".
- Permission strings name the feature and the benefit in one sentence.
- Serif italic (`context.sg.editorial`) is for gentle emphasis in recaps and greetings only.

## Mechanics

- Sentence case everywhere. Overlines stay uppercase by design.
- Use `…` (never `...`). Use curly `’` and `“ ”` in copy, never `\'`.
- No em dashes in UI strings. Use a period, a comma or `·`. A lone `—` as an empty-value placeholder is fine.
- Units: `420 kcal`, `24 g` (always a space), `1,240` (grouped with `NumberFormat`), `70.2 kg`.
- Use numerals ("3 days", "6-digit code").
- US English: analyze, recognize, color, favorite, summarize.
- Plurals go through `Labels.count(n, 'meal')`. Never write "1 meals".
- Never print an enum's `.name` or a raw backend value. Route it through `Labels`.

## Banned (AI tells)

gently, journey, heads-up, "that's fine too", "no need to be exact", beautifully, legendary, "with care", smart (as an adjective), sideways, kitchen, "said no", "thinking with you", "whenever you like", please, "the way you'd tell a friend", lighter/generous/steady day. Also avoid two-sentence explanations of the obvious.

`test/unit/copy/copy_style_test.dart` enforces the mechanical rules and the banned list.

## Glossary: one term per concept

| Concept | Use | Never |
|---|---|---|
| Daily numbers (kcal, macros) | **target** | goal, plan |
| Objective (lose, maintain, gain) and goal weight | **goal** | target |
| Add a meal to the day | **log** | add, track |
| Take an item out of a meal | **remove** | delete |
| Destroy a meal, food or saved meal | **delete** | remove from day |
| Hand entry | **Enter manually** (tray chip: "Manual") | Log it myself, Enter it myself |
| Camera light | **flash** | torch |
| Typing a barcode | **Enter barcode** | Type the code |
| User foods | **My foods** | Custom foods |
| Reusable meals | **Saved meals** / "Save meal" | Templates |
| Relog | **Log again** | Duplicate, copy |
| Sync states | **Synced · Syncing… · Saved on phone · Not synced · Needs review** | All caught up, Needs a retry |
| Unknown meal type | **Other** | Meal |
