/// A meal with known nutrition. `match` lists words any of which identifies
/// the item in a parsed result.
export type EvalCase = {
  id: string;
  text: string;
  locale?: string;
  cuisine_hints?: string[];
  expected: {
    calories_kcal: number;
    protein_g: number;
    items: Array<{ name: string; match: string[] }>;
  };
};

export type ParsedMeal = {
  calories_kcal: number;
  protein_g: number;
  items: string[];
};

export type CaseScore = {
  id: string;
  /// Absolute error as a share of the expected value (0.1 = 10% off).
  caloriesError: number;
  proteinError: number;
  /// Share of expected items found in the result.
  itemRecall: number;
  /// Items in the result that match no expected item.
  extraItems: number;
};

export function scoreCase(evalCase: EvalCase, parsed: ParsedMeal): CaseScore {
  const names = parsed.items.map((name) => name.toLowerCase());
  const used = new Set<number>();
  let found = 0;
  for (const expected of evalCase.expected.items) {
    const index = names.findIndex((name, position) =>
      !used.has(position) &&
      expected.match.some((word) => name.includes(word.toLowerCase()))
    );
    if (index >= 0) {
      used.add(index);
      found += 1;
    }
  }
  return {
    id: evalCase.id,
    caloriesError: relativeError(
      parsed.calories_kcal,
      evalCase.expected.calories_kcal,
    ),
    proteinError: relativeError(parsed.protein_g, evalCase.expected.protein_g),
    itemRecall: evalCase.expected.items.length === 0
      ? 1
      : found / evalCase.expected.items.length,
    extraItems: names.length - used.size,
  };
}

export function summarize(scores: CaseScore[], failed: number) {
  const calories = scores.map((score) => score.caloriesError);
  return {
    cases: scores.length + failed,
    failed,
    calories_mean_error: mean(calories),
    calories_median_error: median(calories),
    calories_within_20pct: scores.length === 0
      ? 0
      : calories.filter((error) => error <= 0.2).length / scores.length,
    protein_mean_error: mean(scores.map((score) => score.proteinError)),
    item_recall: mean(scores.map((score) => score.itemRecall)),
  };
}

function relativeError(actual: number, expected: number) {
  if (expected === 0) return actual === 0 ? 0 : 1;
  return Math.abs(actual - expected) / expected;
}

function mean(values: number[]) {
  return values.length === 0
    ? 0
    : values.reduce((total, value) => total + value, 0) / values.length;
}

function median(values: number[]) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 1
    ? sorted[middle]
    : (sorted[middle - 1] + sorted[middle]) / 2;
}
