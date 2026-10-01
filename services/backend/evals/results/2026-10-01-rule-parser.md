# Baseline: rule parser, 1 October 2026

What the text pipeline scored before any model was involved. Run in endpoint
mode against a local stack with `AI_PROVIDER=mock`, so the keyword parser
answered and its items were grounded in the curated catalog.

Cases: `cases/text_starter.json` (10 Indian home-style meals, reference values
computed from the curated catalog, not weighed).

| Case | Energy error | Protein error | Items found | Extra items | Grounded |
|---|---|---|---|---|---|
| roti-dal | 0.0% | 0.2% | 100.0% | 0 | 100.0% |
| idli-sambar | 0.0% | 0.3% | 100.0% | 0 | 100.0% |
| eggs-banana | 4.2% | 2.8% | 100.0% | 0 | 50.0% |
| rice-curd | 0.0% | 0.6% | 100.0% | 0 | 100.0% |
| chicken-biryani | 48.6% | 193.8% | 100.0% | 1 | 50.0% |
| poha-milk | 0.0% | 0.1% | 100.0% | 0 | 100.0% |
| naan-paneer | 55.6% | 30.9% | 50.0% | 0 | 100.0% |
| dosa-sambar | 72.7% | 55.3% | 50.0% | 0 | 100.0% |
| chole-rice | 58.1% | 75.6% | 50.0% | 0 | 100.0% |
| rajma-chawal | 100.0% | 99.4% | 100.0% | 2 | 100.0% |

| Measure | Result |
|---|---|
| Energy error, mean | 33.9% |
| Energy error, median | 26.4% |
| Energy within 20% | 50.0% |
| Protein error, mean | 45.9% |
| Items found | 85.0% |
| Items grounded | 90.0% |

## What went wrong in the five misses

- **Foods outside the 25-word dictionary are left out**: naan, dosa, chole.
  They are now reported as a warning, but the meal is still logged short.
- **Compound names are counted twice**: "chicken biryani" becomes grilled
  chicken plus biryani; "rajma chawal, one katori of rajma and one bowl of
  rice" becomes two rajma and two rice.

The five meals made only of dictionary foods score within 5%, because the
parser's items are grounded in the same catalog the reference comes from.
That agreement is by construction and says nothing about real-world accuracy.

## Next

Re-run with a real provider configured (`npm run eval:text`, then endpoint
mode) and record the result beside this file. That run is the first accuracy
number for the model-first pipeline.
