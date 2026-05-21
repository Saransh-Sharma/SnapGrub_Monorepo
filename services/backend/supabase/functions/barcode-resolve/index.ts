import { jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { brandedProductToFoodResult, draftFromFoodResult } from "../_shared/multimodal.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    if (req.method !== "POST") throw new ApiError("INVALID_INPUT", "Method not allowed", 405);
    await requireUser(req);
    const body = await req.json().catch(() => {
      throw new ApiError("INVALID_INPUT", "Request body must be valid JSON", 400, false);
    }) as Record<string, unknown>;
    const barcode = String(body.barcode ?? "").replace(/\D/g, "");
    if (barcode.length < 6) throw new ApiError("INVALID_INPUT", "barcode is required", 400, false);
    const timezone = typeof body.timezone === "string" && body.timezone.trim() ? body.timezone.trim() : "UTC";
    const client = serviceClient();

    const local = await readLocalProduct(client, barcode);
    if (local) {
      const product = brandedProductToFoodResult(local);
      return jsonResponse({
        barcode,
        status: "matched",
        product,
        draft: draftFromFoodResult(product, timezone, "barcode"),
        fallback_reason: null,
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    }

    const off = await fetchOpenFoodFacts(barcode);
    if (off) {
      const cached = await cacheOpenFoodFactsProduct(client, barcode, off);
      const product = brandedProductToFoodResult(cached);
      return jsonResponse({
        barcode,
        status: "matched",
        product,
        draft: draftFromFoodResult(product, timezone, "barcode"),
        fallback_reason: null,
        server_time: new Date().toISOString(),
        request_id: requestId,
      });
    }

    return jsonResponse({
      barcode,
      status: "not_found",
      product: null,
      draft: null,
      fallback_reason: "Barcode was not found. Add the product manually or use label OCR.",
      server_time: new Date().toISOString(),
      request_id: requestId,
    });
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

async function readLocalProduct(client: ReturnType<typeof serviceClient>, barcode: string) {
  const { data, error } = await client
    .from("product_barcodes")
    .select("branded_products(*)")
    .eq("barcode", barcode)
    .maybeSingle();
  if (error) throw error;
  const product = data?.branded_products;
  if (Array.isArray(product)) return product[0] as Record<string, unknown> | undefined;
  return product as Record<string, unknown> | null;
}

async function fetchOpenFoodFacts(barcode: string) {
  const response = await fetch(
    `https://world.openfoodfacts.org/api/v2/product/${barcode}.json?fields=code,product_name,brands,serving_quantity,serving_size,nutriments,ingredients_text`,
    { headers: { "user-agent": "SnapGrub MVP - contact@snapgrub.app" } },
  );
  if (!response.ok) return null;
  const raw = await response.json().catch(() => null) as Record<string, unknown> | null;
  if (!raw || raw.status !== 1 || !raw.product) return null;
  return raw.product as Record<string, unknown>;
}

async function cacheOpenFoodFactsProduct(
  client: ReturnType<typeof serviceClient>,
  barcode: string,
  product: Record<string, unknown>,
) {
  const nutriments = (product.nutriments ?? {}) as Record<string, unknown>;
  const servingGrams = parseServingGrams(product.serving_quantity, product.serving_size);
  const calories100 = numberOrNull(nutriments["energy-kcal_100g"]) ?? numberOrNull(nutriments["energy-kcal"]);
  const protein100 = numberOrNull(nutriments.proteins_100g) ?? numberOrNull(nutriments.proteins);
  const carbs100 = numberOrNull(nutriments.carbohydrates_100g) ?? numberOrNull(nutriments.carbohydrates);
  const fat100 = numberOrNull(nutriments.fat_100g) ?? numberOrNull(nutriments.fat);
  const name = stringOrNull(product.product_name) ?? `Barcode ${barcode}`;
  const brand = stringOrNull(product.brands);
  const { data, error } = await client
    .from("branded_products")
    .upsert({
      name,
      brand,
      normalized_name: name.toLowerCase(),
      serving_quantity: 1,
      serving_unit: "serving",
      serving_grams: servingGrams,
      calories_kcal_per_100g: calories100 ?? 0,
      protein_g_per_100g: protein100 ?? 0,
      carbs_g_per_100g: carbs100 ?? 0,
      fat_g_per_100g: fat100 ?? 0,
      calories_kcal_per_serving: perServing(calories100, servingGrams),
      protein_g_per_serving: perServing(protein100, servingGrams),
      carbs_g_per_serving: perServing(carbs100, servingGrams),
      fat_g_per_serving: perServing(fat100, servingGrams),
      ingredients_text: stringOrNull(product.ingredients_text),
      source_type: "open_food_facts",
      source_id: barcode,
      license_tag: "ODbL/CC-BY-SA",
      source_quality: "external",
      raw_payload: product,
      last_verified_at: new Date().toISOString(),
    }, { onConflict: "source_type,source_id" })
    .select("*")
    .single();
  if (error) throw error;

  const { error: barcodeError } = await client
    .from("product_barcodes")
    .upsert({ barcode, branded_product_id: data.id, region: null }, { onConflict: "barcode" });
  if (barcodeError) throw barcodeError;
  return data as Record<string, unknown>;
}

function parseServingGrams(quantity: unknown, servingSize: unknown) {
  const quantityNumber = typeof quantity === "string" ? Number(quantity) : numberOrNull(quantity);
  if (quantityNumber != null && Number.isFinite(quantityNumber)) return quantityNumber;
  if (typeof servingSize === "string") {
    const match = servingSize.match(/(\d+(?:\.\d+)?)\s*g/i);
    if (match) return Number(match[1]);
  }
  return null;
}

function numberOrNull(value: unknown) {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function stringOrNull(value: unknown) {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function perServing(per100g: number | null, grams: number | null) {
  if (per100g == null || grams == null) return null;
  return Number((per100g * grams / 100).toFixed(2));
}
