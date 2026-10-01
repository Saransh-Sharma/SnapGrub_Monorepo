# Accuracy evals

Scores the meal-logging pipeline against meals whose nutrition is known, so a
prompt, model or catalog change can be judged by a number instead of by feel.
Past runs are kept in `results/`.

## Run

Model only, using the provider configured in the environment:

```bash
AI_PROVIDER=gemini GEMINI_API_KEY=... deno run --allow-env --allow-net --allow-read services/backend/evals/run.ts
```

Full pipeline, including catalog grounding, against a running project:

```bash
deno run --allow-env --allow-net --allow-read services/backend/evals/run.ts --endpoint http://127.0.0.1:54321/functions/v1 --token <user JWT> --anon-key <anon key>
```

Add `--cases <file.json>` (repeatable) for other case files and `--json` for
machine-readable output. The run exits non-zero if any case fails to parse.

Each run makes one provider call per case and counts against the caller's
daily AI budget in endpoint mode. Run it before a prompt or model change, not
on every pull request.

## What is reported

- Energy error: absolute difference from the reference, as a share of it.
  Mean, median, and the share of meals within 20%.
- Protein error: the same, mean only.
- Items found: share of the reference items present in the result.
- Extra items: parsed items that match nothing in the reference.
- Items grounded: share of parsed items whose nutrition came from the catalog
  or the user's own foods. Endpoint mode only; model-only runs report 0%.

## Cases

`cases/text_starter.json` holds 10 Indian home-style meals. Its reference
values are computed from the curated catalog, not from weighed food. That
makes it a regression check for parsing and portion logic. In endpoint mode,
items grounded in the same catalog will agree with it by construction, so it
is not an accuracy claim.

For a number worth publishing, add weighed meals: cook or plate the meal,
weigh each component, compute nutrition from a trusted table, and record it
in the same shape under `cases/`. Aim for 100 or more, weighted toward the
cuisines the app serves.

## Photo cases

A case with `image` instead of `text` is a photo case. The path is relative to
the case file, and `hint` is sent as the note a user can attach.

```json
{ "cases": [ { "id": "thali-1", "image": "photos/thali-1.jpg",
  "expected": { "calories_kcal": 640, "protein_g": 22,
    "items": [ { "name": "Roti", "match": ["roti", "chapati"] } ] } } ] }
```

Photo cases need endpoint mode: each image is uploaded to the caller's private
storage prefix and sent through `analysis-photo-create`. No photo cases ship
with the repo; they need real meal photos with weighed reference values.
