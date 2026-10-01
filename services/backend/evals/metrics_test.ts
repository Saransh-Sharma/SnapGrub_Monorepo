import { type EvalCase, scoreCase, summarize } from "./metrics.ts";

function assertEquals(actual: unknown, expected: unknown, message: string) {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `${message}: expected ${JSON.stringify(expected)}, got ${
        JSON.stringify(actual)
      }`,
    );
  }
}

const rotiDal: EvalCase = {
  id: "roti-dal",
  text: "2 rotis and dal",
  expected: {
    calories_kcal: 400,
    protein_g: 20,
    items: [
      { name: "Roti", match: ["roti", "chapati"] },
      { name: "Dal", match: ["dal"] },
    ],
  },
};

Deno.test("a case is scored on energy, protein and items found", () => {
  const score = scoreCase(rotiDal, {
    calories_kcal: 440,
    protein_g: 15,
    items: ["Chapati", "Salad"],
  });
  assertEquals(score.caloriesError.toFixed(2), "0.10", "10% over on energy");
  assertEquals(score.proteinError.toFixed(2), "0.25", "25% under on protein");
  assertEquals(score.itemRecall, 0.5, "one of two expected items was found");
  assertEquals(score.extraItems, 1, "the salad was not expected");
});

Deno.test("one parsed item cannot satisfy two expected items", () => {
  const score = scoreCase(rotiDal, {
    calories_kcal: 400,
    protein_g: 20,
    items: ["Roti with dal"],
  });
  assertEquals(score.itemRecall, 0.5, "a merged item counts once");
});

Deno.test("the summary reports mean, median and the share within 20%", () => {
  const summary = summarize([
    { id: "a", caloriesError: 0.1, proteinError: 0.2, itemRecall: 1, extraItems: 0 },
    { id: "b", caloriesError: 0.3, proteinError: 0.4, itemRecall: 0.5, extraItems: 0 },
    { id: "c", caloriesError: 0.2, proteinError: 0, itemRecall: 1, extraItems: 1 },
  ], 1);
  assertEquals(summary.cases, 4, "failed cases are counted");
  assertEquals(summary.failed, 1, "and reported");
  assertEquals(summary.calories_mean_error.toFixed(2), "0.20", "mean");
  assertEquals(summary.calories_median_error, 0.2, "median");
  assertEquals(summary.calories_within_20pct.toFixed(2), "0.67", "2 of 3");
  assertEquals(summary.item_recall.toFixed(2), "0.83", "mean recall");
});
