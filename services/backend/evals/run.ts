// Scores the meal-logging pipeline against meals with known nutrition.
//
// Text, model only (needs AI_PROVIDER and the provider key in the environment):
//   deno run --allow-env --allow-net --allow-read services/backend/evals/run.ts
//
// Full pipeline including catalog grounding, against a running project. Photo
// cases need this mode, because the image has to be uploaded and analysed:
//   deno run --allow-env --allow-net --allow-read services/backend/evals/run.ts \
//     --endpoint http://127.0.0.1:54321/functions/v1 --token <user JWT> --anon-key <anon key> \
//     --cases services/backend/evals/cases/photos.json
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

const PHOTO_BUCKET = "meal-originals-private";

const args = Deno.args;
const option = (name: string) => {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
};
const options = (name: string) =>
  args.flatMap((arg, index) => arg === name ? [args[index + 1]] : []);

const endpoint = option("--endpoint")?.replace(/\/$/, "");
const token = option("--token");
const anonKey = option("--anon-key") ?? Deno.env.get("SUPABASE_ANON_KEY");
const caseFiles = options("--cases");
if (caseFiles.length === 0) {
  // decodeURIComponent: a checkout path with a space arrives as "%20".
  caseFiles.push(
    decodeURIComponent(
      new URL("./cases/text_starter.json", import.meta.url).pathname,
    ),
  );
}
if (endpoint && !token) {
  console.error("--endpoint needs --token <user JWT>.");
  Deno.exit(2);
}

type LoadedCase = EvalCase & { baseDir: string };
const cases: LoadedCase[] = [];
for (const file of caseFiles) {
  const loaded = JSON.parse(await Deno.readTextFile(file));
  for (const evalCase of (loaded.cases ?? loaded) as EvalCase[]) {
    if (!evalCase.text && !evalCase.image) {
      console.error(`Case ${evalCase.id} in ${file} has neither text nor image.`);
      Deno.exit(2);
    }
    cases.push({
      ...evalCase,
      baseDir: file.includes("/") ? file.slice(0, file.lastIndexOf("/")) : ".",
    });
  }
}
if (!endpoint && cases.some((evalCase) => evalCase.image)) {
  console.error("Photo cases need --endpoint; they cannot run model-only.");
  Deno.exit(2);
}
if (!endpoint && !textModelConfig()) {
  console.error(
    "No model is configured. Set AI_PROVIDER and the provider key, or pass --endpoint.",
  );
  Deno.exit(2);
}

const authHeaders: Record<string, string> = {
  authorization: `Bearer ${token}`,
  ...(anonKey ? { apikey: anonKey } : {}),
};

async function invoke(path: string, body: Record<string, unknown>) {
  const response = await fetch(`${endpoint}/${path}`, {
    method: "POST",
    headers: { "content-type": "application/json", ...authHeaders },
    body: JSON.stringify(body),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || !payload.result) {
    throw new Error(
      payload.message ?? payload.error_code ?? `HTTP ${response.status}`,
    );
  }
  return mealOf(payload.result);
}

async function parseText(evalCase: LoadedCase): Promise<ParsedMeal> {
  const locale = evalCase.locale ?? "en-IN";
  const cuisineHints = evalCase.cuisine_hints ?? [];
  if (endpoint) {
    return await invoke("analysis-text-create", {
      client_request_id: crypto.randomUUID(),
      text: evalCase.text,
      locale,
      timezone: "Asia/Kolkata",
      cuisine_hints: cuisineHints,
    });
  }
  const result = await parseMealText({
    text: evalCase.text!,
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

async function parsePhoto(evalCase: LoadedCase): Promise<ParsedMeal> {
  const bytes = await Deno.readFile(`${evalCase.baseDir}/${evalCase.image}`);
  const mimeType = /\.png$/i.test(evalCase.image!)
    ? "image/png"
    : /\.webp$/i.test(evalCase.image!)
    ? "image/webp"
    : "image/jpeg";
  const storagePath = `${userIdFromToken(token!)}/eval-${crypto.randomUUID()}`;
  const upload = await fetch(
    `${endpoint!.replace(/\/functions\/v1$/, "")}/storage/v1/object/${PHOTO_BUCKET}/${storagePath}`,
    {
      method: "POST",
      headers: { "content-type": mimeType, ...authHeaders },
      body: bytes,
    },
  );
  if (!upload.ok) {
    throw new Error(`Upload failed: HTTP ${upload.status} ${await upload.text()}`);
  }
  return await invoke("analysis-photo-create", {
    client_request_id: crypto.randomUUID(),
    storage_path: storagePath,
    mime_type: mimeType,
    locale: evalCase.locale ?? "en-IN",
    timezone: "Asia/Kolkata",
    cuisine_hints: evalCase.cuisine_hints ?? [],
    user_hint_text: evalCase.hint ?? null,
  });
}

/// The `sub` claim of a Supabase user JWT; uploads must sit under it.
function userIdFromToken(jwt: string) {
  const payload = jwt.split(".")[1] ?? "";
  const json = atob(payload.replace(/-/g, "+").replace(/_/g, "/"));
  const sub = JSON.parse(json).sub;
  if (typeof sub !== "string") throw new Error("--token is not a user JWT.");
  return sub;
}

function mealOf(draft: {
  total: { calories_kcal: number; protein_g: number };
  components: Array<{ name: string; food_ref_kind?: string }>;
}): ParsedMeal {
  return {
    calories_kcal: draft.total.calories_kcal,
    protein_g: draft.total.protein_g,
    items: draft.components.map((component) => component.name),
    grounded: draft.components.filter((component) =>
      component.food_ref_kind != null && component.food_ref_kind !== "manual"
    ).length,
  };
}

const scores: CaseScore[] = [];
const failures: Array<{ id: string; error: string }> = [];
for (const evalCase of cases) {
  try {
    const parsed = evalCase.image
      ? await parsePhoto(evalCase)
      : await parseText(evalCase);
    scores.push(scoreCase(evalCase, parsed));
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
  console.log(
    "| Case | Energy error | Protein error | Items found | Extra items | Grounded |",
  );
  console.log("|---|---|---|---|---|---|");
  for (const score of scores) {
    console.log(
      `| ${score.id} | ${pct(score.caloriesError)} | ${
        pct(score.proteinError)
      } | ${pct(score.itemRecall)} | ${score.extraItems} | ${
        pct(score.groundedShare)
      } |`,
    );
  }
  for (const failure of failures) {
    console.log(`| ${failure.id} | failed: ${failure.error} | | | | |`);
  }
  console.log("");
  console.log(`Cases: ${summary.cases} (${summary.failed} failed)`);
  console.log(`Energy error, mean: ${pct(summary.calories_mean_error)}`);
  console.log(`Energy error, median: ${pct(summary.calories_median_error)}`);
  console.log(`Energy within 20%: ${pct(summary.calories_within_20pct)}`);
  console.log(`Protein error, mean: ${pct(summary.protein_mean_error)}`);
  console.log(`Items found: ${pct(summary.item_recall)}`);
  console.log(`Items grounded: ${pct(summary.grounded_share)}`);
}
Deno.exit(failures.length > 0 ? 1 : 0);
