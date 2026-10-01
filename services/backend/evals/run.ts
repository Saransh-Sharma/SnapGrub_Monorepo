// Scores the text-logging pipeline against meals with known nutrition.
//
// Model only (needs AI_PROVIDER and the provider key in the environment):
//   deno run --allow-env --allow-net --allow-read services/backend/evals/run.ts
//
// Full pipeline including catalog grounding, against a running project:
//   deno run --allow-env --allow-net --allow-read services/backend/evals/run.ts \
//     --endpoint http://127.0.0.1:54321/functions/v1 --token <user JWT> --anon-key <anon key>
//
// Options: --cases <file.json> (repeatable), --json (machine-readable output).
import { textModelConfig } from "../supabase/functions/_shared/llm.ts";
import { parseMealText } from "../supabase/functions/_shared/meal_llm.ts";
import {
  type CaseScore,
  type EvalCase,
  type ParsedMeal,
  scoreCase,
  summarize,
} from "./metrics.ts";

const args = Deno.args;
const option = (name: string) => {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
};
const options = (name: string) =>
  args.flatMap((arg, index) => arg === name ? [args[index + 1]] : []);

const endpoint = option("--endpoint");
const token = option("--token");
const anonKey = option("--anon-key") ?? Deno.env.get("SUPABASE_ANON_KEY");
const caseFiles = options("--cases");
if (caseFiles.length === 0) {
  caseFiles.push(new URL("./cases/text_starter.json", import.meta.url).pathname);
}

if (!endpoint && !textModelConfig()) {
  console.error(
    "No model is configured. Set AI_PROVIDER and the provider key, or pass --endpoint.",
  );
  Deno.exit(2);
}
if (endpoint && !token) {
  console.error("--endpoint needs --token <user JWT>.");
  Deno.exit(2);
}

const cases: EvalCase[] = [];
for (const file of caseFiles) {
  const loaded = JSON.parse(await Deno.readTextFile(file));
  cases.push(...(loaded.cases ?? loaded));
}

async function parse(evalCase: EvalCase): Promise<ParsedMeal> {
  const locale = evalCase.locale ?? "en-IN";
  const cuisineHints = evalCase.cuisine_hints ?? [];
  if (endpoint) {
    const response = await fetch(`${endpoint}/analysis-text-create`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
        ...(anonKey ? { apikey: anonKey } : {}),
      },
      body: JSON.stringify({
        client_request_id: crypto.randomUUID(),
        text: evalCase.text,
        locale,
        timezone: "Asia/Kolkata",
        cuisine_hints: cuisineHints,
      }),
    });
    const body = await response.json();
    if (!response.ok || !body.result) {
      throw new Error(body.message ?? `HTTP ${response.status}`);
    }
    return mealOf(body.result);
  }
  const result = await parseMealText({
    text: evalCase.text,
    source: "text",
    timezone: "Asia/Kolkata",
    locale,
    cuisineHints,
    mealTypeHint: null,
  });
  if (result.provider === "snapgrub") {
    throw new Error("The model was unavailable and the rule parser answered.");
  }
  return mealOf(result.draft);
}

function mealOf(draft: {
  total: { calories_kcal: number; protein_g: number };
  components: Array<{ name: string }>;
}): ParsedMeal {
  return {
    calories_kcal: draft.total.calories_kcal,
    protein_g: draft.total.protein_g,
    items: draft.components.map((component) => component.name),
  };
}

const scores: CaseScore[] = [];
const failures: Array<{ id: string; error: string }> = [];
for (const evalCase of cases) {
  try {
    scores.push(scoreCase(evalCase, await parse(evalCase)));
  } catch (error) {
    failures.push({
      id: evalCase.id,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}
const summary = summarize(scores, failures.length);

if (args.includes("--json")) {
  console.log(JSON.stringify({ summary, scores, failures }, null, 2));
} else {
  const pct = (value: number) => `${(value * 100).toFixed(1)}%`;
  console.log("| Case | Energy error | Protein error | Items found | Extra items |");
  console.log("|---|---|---|---|---|");
  for (const score of scores) {
    console.log(
      `| ${score.id} | ${pct(score.caloriesError)} | ${
        pct(score.proteinError)
      } | ${pct(score.itemRecall)} | ${score.extraItems} |`,
    );
  }
  for (const failure of failures) {
    console.log(`| ${failure.id} | failed: ${failure.error} | | | |`);
  }
  console.log("");
  console.log(`Cases: ${summary.cases} (${summary.failed} failed)`);
  console.log(`Energy error, mean: ${pct(summary.calories_mean_error)}`);
  console.log(`Energy error, median: ${pct(summary.calories_median_error)}`);
  console.log(`Energy within 20%: ${pct(summary.calories_within_20pct)}`);
  console.log(`Protein error, mean: ${pct(summary.protein_mean_error)}`);
  console.log(`Items found: ${pct(summary.item_recall)}`);
}
Deno.exit(failures.length > 0 ? 1 : 0);
