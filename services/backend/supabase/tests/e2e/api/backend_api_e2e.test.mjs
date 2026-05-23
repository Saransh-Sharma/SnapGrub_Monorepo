import assert from "node:assert/strict";
import { test } from "node:test";
import {
  admin,
  anonKey,
  assertError,
  assertOk,
  createSignedInUser,
  deleteUsers,
  fakeServiceRoleJwt,
  invoke,
  invokeAnon,
  invokeService,
  invokeUser,
  onePixelJpeg,
  serviceRoleKey,
  uploadUserObject,
} from "./helpers.mjs";
import { assertResponseMatchesContract } from "./contracts.mjs";

const testUsers = new Set();

test("backend API E2E covers critical Supabase Edge Function surface", async (t) => {
  t.after(async () => {
    await deleteUsers(testUsers);
  });

  const userA = await trackedUser("api-e2e-a");
  const userB = await trackedUser("api-e2e-b", { profile: true, displayName: "API E2E B" });
  const state = {};

  await t.test("auth, bootstrap, settings, and analytics APIs", async () => {
    const installId = `install-${crypto.randomUUID()}`;
    const bootstrap = assertOk(await invokeUser(userA, "profile-bootstrap", {
      body: {
        install_id: installId,
        platform: "ios",
        app_version: "0.1.0",
        build_number: "1",
        locale: "en-IN",
        timezone: "Asia/Kolkata",
      },
    }));
    assertResponseMatchesContract("profileBootstrap", 200, bootstrap);
    assert.equal(bootstrap.profile.id, userA.id);
    assert.equal(bootstrap.device.install_id, installId);
    assert.equal(typeof bootstrap.feature_flags, "object");

    const takeover = await invokeUser(userB, "profile-bootstrap", {
      body: { install_id: installId, platform: "ios", timezone: "Asia/Kolkata" },
    });
    assertError(takeover, 409, "CONFLICT");

    const settingsRequestId = crypto.randomUUID();
    const settingsBody = {
      client_request_id: settingsRequestId,
      profile_patch: {
        display_name: "API E2E A",
        timezone: "Asia/Kolkata",
        locale: "en-IN",
        cloud_media_storage: true,
        save_original_photos: true,
        ai_improvement_consent: true,
        onboarding_completed_at: new Date().toISOString(),
      },
      active_goal_patch: {
        goal_type: "maintain",
        calories_kcal: 2100,
        protein_g: 130,
        carbs_g: 240,
        fat_g: 70,
      },
      body_measurement: {
        weight_kg: 70,
        body_fat_pct: 20,
        source: "onboarding",
      },
    };
    const settings = assertOk(await invokeUser(userA, "settings-patch", {
      method: "PATCH",
      headers: { "Idempotency-Key": settingsRequestId },
      body: settingsBody,
    }));
    assertResponseMatchesContract("settingsPatch", 200, settings);
    assert.equal(settings.profile.display_name, "API E2E A");
    assert.equal(settings.active_goal.calories_kcal, 2100);
    assert.equal(settings.body_measurement.weight_kg, 70);

    const settingsReplay = assertOk(await invokeUser(userA, "settings-patch", {
      method: "PATCH",
      headers: { "Idempotency-Key": settingsRequestId },
      body: settingsBody,
    }));
    assert.equal(settingsReplay.request_id, settings.request_id);
    assert.equal(settingsReplay.profile.display_name, settings.profile.display_name);

    const settingsConflict = await invokeUser(userA, "settings-patch", {
      method: "PATCH",
      headers: { "Idempotency-Key": settingsRequestId },
      body: { ...settingsBody, profile_patch: { display_name: "Different" } },
    });
    assertError(settingsConflict, 409, "IDEMPOTENCY_CONFLICT");

    const eventsRequestId = crypto.randomUUID();
    const events = assertOk(await invokeUser(userA, "events-ingest", {
      headers: { "Idempotency-Key": eventsRequestId },
      body: {
        client_request_id: eventsRequestId,
        events: [{
          event_name: "api_e2e_authenticated",
          properties: { source: "backend_api_e2e" },
          occurred_at: new Date().toISOString(),
        }],
      },
    }));
    assert.equal(events.accepted, 1);

    const anonymousEvents = assertOk(await invokeAnon("events-ingest", {
      body: {
        events: [{
          event_name: "api_e2e_anonymous",
          properties: { source: "backend_api_e2e" },
          occurred_at: new Date().toISOString(),
        }],
      },
    }));
    assert.equal(anonymousEvents.accepted, 1);

    const invalidEvents = await invokeUser(userA, "events-ingest", {
      body: { events: [{ event_name: "Not Snake", properties: [] }] },
    });
    assertError(invalidEvents, 400, "INVALID_INPUT");

    const { data: rows, error } = await admin
      .from("analytics_events")
      .select("event_name,user_id")
      .in("event_name", ["api_e2e_authenticated", "api_e2e_anonymous"]);
    if (error) throw error;
    assert.ok(rows.some((row) => row.event_name === "api_e2e_authenticated" && row.user_id === userA.id));
    assert.ok(rows.some((row) => row.event_name === "api_e2e_anonymous" && row.user_id == null));
  });

  await t.test("meal ledger APIs and offline replay APIs", async () => {
    const mealCreateBody = mealBody({
      title: "API E2E dal roti",
      loggedAt: "2026-05-20T07:30:00.000Z",
      calories: 450,
    });
    const created = assertOk(await invokeUser(userA, "meals", {
      headers: { "Idempotency-Key": mealCreateBody.client_request_id },
      body: mealCreateBody,
    }));
    assertResponseMatchesContract("createMeal", 200, created);
    assert.equal(created.meal.title, "API E2E dal roti");
    assert.equal(created.daily_rollup.calories_kcal, 450);
    assert.equal(created.correction_events[0].event_type, "meal_created");
    state.mealId = created.meal.id;
    state.mealRevision = created.meal.revision;

    const list = assertOk(await invokeUser(userA, "meals?day=2026-05-20", { method: "GET" }));
    assertResponseMatchesContract("listMeals", 200, list);
    assert.ok(list.meals.some((meal) => meal.id === state.mealId));
    assert.ok(list.daily_rollups.some((rollup) => rollup.day === "2026-05-20"));

    const detail = assertOk(await invokeUser(userA, `meals/${state.mealId}`, { method: "GET" }));
    assertResponseMatchesContract("getMeal", 200, detail);
    assert.equal(detail.meal.items.length, 1);

    const duplicateBody = mealBody({ title: "API E2E dal roti copy", calories: 450 });
    const duplicate = assertOk(await invokeUser(userA, "meals", {
      headers: { "Idempotency-Key": duplicateBody.client_request_id },
      body: duplicateBody,
    }));
    state.activeMealId = duplicate.meal.id;
    assert.notEqual(duplicate.meal.id, state.mealId);

    const updateBody = {
      ...mealCreateBody,
      client_request_id: crypto.randomUUID(),
      title: "API E2E dal roti edited",
      expected_revision: state.mealRevision,
      items: [
        mealCreateBody.items[0],
        {
          client_id: crypto.randomUUID(),
          position: 1,
          name: "Curd",
          food_ref_kind: "manual",
          quantity: 1,
          unit: "katori",
          calories_kcal: 73,
          protein_g: 4.2,
          carbs_g: 5.6,
          fat_g: 4,
        },
      ],
    };
    const updated = assertOk(await invokeUser(userA, `meals/${state.mealId}`, {
      method: "PATCH",
      headers: { "Idempotency-Key": updateBody.client_request_id },
      body: updateBody,
    }));
    assertResponseMatchesContract("updateMeal", 200, updated);
    assert.equal(updated.meal.revision, state.mealRevision + 1);
    assert.equal(updated.daily_rollup.calories_kcal, 973);

    const staleUpdate = await invokeUser(userA, `meals/${state.mealId}`, {
      method: "PATCH",
      body: { ...updateBody, client_request_id: crypto.randomUUID(), expected_revision: state.mealRevision },
    });
    assertError(staleUpdate, 409, "CONFLICT");

    const crossUserRead = await invokeUser(userB, `meals/${state.activeMealId}`, { method: "GET" });
    assertError(crossUserRead, 404, "NOT_FOUND");

    const deleted = assertOk(await invokeUser(userA, `meals/${state.mealId}`, {
      method: "DELETE",
      headers: { "Idempotency-Key": crypto.randomUUID() },
      body: { client_request_id: crypto.randomUUID(), expected_revision: updated.meal.revision },
    }));
    assertResponseMatchesContract("deleteMeal", 200, deleted);
    assert.ok(deleted.meal.deleted_at);
    const deletedRead = await invokeUser(userA, `meals/${state.mealId}`, { method: "GET" });
    assertError(deletedRead, 404, "NOT_FOUND");

    const customFoodBody = {
      client_request_id: crypto.randomUUID(),
      client_id: crypto.randomUUID(),
      name: "API E2E almond chutney",
      brand: "Home",
      serving_quantity: 1,
      serving_unit: "tbsp",
      serving_grams: 15,
      calories_kcal: 80,
      protein_g: 3,
      carbs_g: 4,
      fat_g: 6,
    };
    const customFood = assertOk(await invokeUser(userA, "custom-foods", {
      headers: { "Idempotency-Key": customFoodBody.client_request_id },
      body: customFoodBody,
    }));
    assertResponseMatchesContract("customFoodsUpsert", 200, customFood);
    state.customFoodId = customFood.custom_food.id;

    const customFoodReplay = assertOk(await invokeUser(userA, "custom-foods", {
      headers: { "Idempotency-Key": customFoodBody.client_request_id },
      body: customFoodBody,
    }));
    assert.equal(customFoodReplay.custom_food.id, state.customFoodId);

    const invalidCustomFood = await invokeUser(userA, "custom-foods", {
      body: { ...customFoodBody, client_request_id: crypto.randomUUID(), client_id: crypto.randomUUID(), calories_kcal: -1 },
    });
    assertError(invalidCustomFood, 400, "INVALID_INPUT");

    const deletedCustomFood = assertOk(await invokeUser(userA, "custom-foods", {
      body: {
        client_request_id: crypto.randomUUID(),
        client_id: customFoodBody.client_id,
        deleted_at: new Date().toISOString(),
      },
    }));
    assert.ok(deletedCustomFood.custom_food.deleted_at);

    const templateBody = {
      client_request_id: crypto.randomUUID(),
      client_id: crypto.randomUUID(),
      title: "API E2E lunch template",
      source_meal_id: state.activeMealId,
      snapshot: { meal_id: state.activeMealId, title: "API E2E dal roti copy" },
    };
    const template = assertOk(await invokeUser(userA, "meal-templates", { body: templateBody }));
    assertResponseMatchesContract("mealTemplatesUpsert", 200, template);
    const templateDelete = assertOk(await invokeUser(userA, "meal-templates", {
      body: {
        client_request_id: crypto.randomUUID(),
        client_id: templateBody.client_id,
        deleted_at: new Date().toISOString(),
      },
    }));
    assert.ok(templateDelete.meal_template.deleted_at);

    const measurementBody = {
      client_request_id: crypto.randomUUID(),
      measured_at: "2026-05-20T08:00:00.000Z",
      weight_kg: 71,
      body_fat_pct: 19.5,
      source: "manual",
    };
    const measurement = assertOk(await invokeUser(userA, "body-measurements", {
      headers: { "Idempotency-Key": measurementBody.client_request_id },
      body: measurementBody,
    }));
    assertResponseMatchesContract("bodyMeasurementCreate", 200, measurement);
    const invalidMeasurement = await invokeUser(userA, "body-measurements", {
      body: { client_request_id: crypto.randomUUID(), weight_kg: 2, source: "manual" },
    });
    assertError(invalidMeasurement, 400, "INVALID_INPUT");
  });

  await t.test("catalog, barcode, and multimodal analysis APIs", async () => {
    const searchCanonical = assertOk(await invokeUser(userA, "foods-search", {
      body: { query: "roti", limit: 5 },
    }));
    assertResponseMatchesContract("foodsSearch", 200, searchCanonical);
    assert.ok(searchCanonical.results.some((result) => result.name.toLowerCase().includes("roti")));

    const searchRecent = assertOk(await invokeUser(userA, "foods-search", {
      body: { query: "dal", limit: 10 },
    }));
    assert.ok(searchRecent.results.some((result) => ["recent", "canonical"].includes(result.result_type)));

    const barcode = assertOk(await invokeUser(userA, "barcode-resolve", {
      body: { barcode: "8901719101018", timezone: "Asia/Kolkata" },
    }));
    assertResponseMatchesContract("barcodeResolve", 200, barcode);
    assert.equal(barcode.status, "matched");
    assert.ok(barcode.draft.components.length >= 1);

    const missBarcode = `99${String(Math.trunc(Math.random() * 1_000_000_000)).padStart(9, "0")}`;
    const { error: missSeedError } = await admin.from("barcode_lookup_misses").upsert({
      barcode: missBarcode,
      provider: "open_food_facts",
      reason: "not_found",
      checked_at: new Date().toISOString(),
      expires_at: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
    }, { onConflict: "barcode" });
    if (missSeedError) throw missSeedError;
    const barcodeMiss = assertOk(await invokeUser(userA, "barcode-resolve", {
      body: { barcode: missBarcode, timezone: "Asia/Kolkata" },
    }));
    assert.equal(barcodeMiss.status, "not_found");
    assert.equal(barcodeMiss.product, null);

    const textRequestId = crypto.randomUUID();
    const textAnalysis = assertOk(await invokeUser(userA, "analysis-text-create", {
      body: {
        client_request_id: textRequestId,
        text: "2 rotis and dal",
        locale: "en-IN",
        timezone: "Asia/Kolkata",
        meal_type_hint: "lunch",
        cuisine_hints: ["Indian"],
      },
    }));
    assertResponseMatchesContract("analysisTextCreate", 200, textAnalysis);
    assert.equal(textAnalysis.status, "completed");
    assert.ok(textAnalysis.result.components.length >= 2);

    const textReplay = assertOk(await invokeUser(userA, "analysis-text-create", {
      body: {
        client_request_id: textRequestId,
        text: "2 rotis and dal",
        locale: "en-IN",
        timezone: "Asia/Kolkata",
        meal_type_hint: "lunch",
        cuisine_hints: ["Indian"],
      },
    }));
    assert.equal(textReplay.analysis_id, textAnalysis.analysis_id);

    const labelAnalysis = assertOk(await invokeUser(userA, "analysis-label-create", {
      body: {
        client_request_id: crypto.randomUUID(),
        ocr_text: "Product Name API Bar Serving Size 40 g Calories 160 Protein 5 Carbohydrate 22 Total Fat 6",
        product_name_hint: "API Bar",
        barcode: "1234567890123",
        locale: "en-IN",
        timezone: "Asia/Kolkata",
        raw_image_opt_in: false,
      },
    }));
    assertResponseMatchesContract("analysisLabelCreate", 200, labelAnalysis);
    assert.equal(labelAnalysis.result.title, "API Bar");

    const voiceAnalysis = assertOk(await invokeUser(userA, "analysis-voice-create", {
      body: {
        client_request_id: crypto.randomUUID(),
        transcript: "one bowl rice and curd",
        transcript_confidence: 0.5,
        locale: "en-IN",
        timezone: "Asia/Kolkata",
      },
    }));
    assertResponseMatchesContract("analysisVoiceCreate", 200, voiceAnalysis);
    assert.ok(voiceAnalysis.result.confidence.warnings.some((warning) => warning.code === "low_transcript_confidence"));

    const { data: invocation, error: invocationError } = await admin
      .from("model_invocations")
      .select("request_payload,response_payload")
      .eq("analysis_job_id", textAnalysis.analysis_id)
      .single();
    if (invocationError) throw invocationError;
    assert.equal(invocation.request_payload.text, undefined);
    assert.equal(typeof invocation.response_payload.component_count, "number");
  });

  await t.test("photo analysis API and photo meal save protections", async () => {
    const storagePath = `${userA.id}/${crypto.randomUUID()}.jpg`;
    await uploadUserObject(userA, "meal-originals-private", storagePath, onePixelJpeg, "image/jpeg");

    const photoAnalysis = assertOk(await invokeUser(userA, "analysis-photo-create", {
      body: {
        client_request_id: crypto.randomUUID(),
        storage_bucket: "meal-originals-private",
        storage_path: storagePath,
        asset_sha256: crypto.randomUUID().replaceAll("-", ""),
        mime_type: "image/jpeg",
        width: 1,
        height: 1,
        size_bytes: onePixelJpeg.length,
        locale: "en-IN",
        timezone: "Asia/Kolkata",
        meal_type_hint: "lunch",
        cuisine_hints: ["Indian"],
        user_hint_text: "dal and roti",
      },
    }));
    assertResponseMatchesContract("analysisPhotoCreate", 200, photoAnalysis);
    assert.equal(photoAnalysis.status, "completed");
    assert.ok(photoAnalysis.asset_id);
    assert.ok(photoAnalysis.result.title);
    state.photoAnalysisId = photoAnalysis.analysis_id;
    state.photoAssetId = photoAnalysis.asset_id;

    const recovered = assertOk(await invokeUser(userA, `analysis-get/${photoAnalysis.analysis_id}`, { method: "GET" }));
    assertResponseMatchesContract("analysisGet", 200, recovered);
    assert.equal(recovered.analysis_id, photoAnalysis.analysis_id);
    assert.equal(recovered.result.title, photoAnalysis.result.title);

    const photoMealBody = {
      client_request_id: crypto.randomUUID(),
      client_id: crypto.randomUUID(),
      title: `Saved ${photoAnalysis.result.title}`,
      meal_type: photoAnalysis.result.meal_type,
      source: "photo",
      logged_at: photoAnalysis.result.logged_at,
      timezone: photoAnalysis.result.timezone,
      analysis_job_id: photoAnalysis.analysis_id,
      photo_asset_id: photoAnalysis.asset_id,
      confidence_overall: photoAnalysis.result.confidence.overall,
      provenance_type: "ai_photo",
      items: photoAnalysis.result.components.map((item, index) => ({
        ...item,
        client_id: crypto.randomUUID(),
        position: index,
      })),
    };
    const photoMeal = assertOk(await invokeUser(userA, "meals", {
      headers: { "Idempotency-Key": photoMealBody.client_request_id },
      body: photoMealBody,
    }));
    assert.equal(photoMeal.meal.source, "photo");
    assert.equal(photoMeal.meal.analysis_job_id, photoAnalysis.analysis_id);

    const forgedPhotoMeal = await invokeUser(userA, "meals", {
      body: {
        ...mealBody({ title: "Forged photo refs", calories: 1 }),
        source: "photo",
        analysis_job_id: crypto.randomUUID(),
        photo_asset_id: photoAnalysis.asset_id,
      },
    });
    assertError(forgedPhotoMeal, 400, "INVALID_INPUT");

    const badStoragePath = await invokeUser(userA, "analysis-photo-create", {
      body: {
        client_request_id: crypto.randomUUID(),
        storage_bucket: "meal-originals-private",
        storage_path: `${userB.id}/not-owned.jpg`,
        locale: "en-IN",
        timezone: "Asia/Kolkata",
      },
    });
    assertError(badStoragePath, 400, "INVALID_INPUT");

    const badBucket = await invokeUser(userA, "analysis-photo-create", {
      body: {
        client_request_id: crypto.randomUUID(),
        storage_bucket: "exports-private",
        storage_path: storagePath,
        locale: "en-IN",
        timezone: "Asia/Kolkata",
      },
    });
    assertError(badBucket, 400, "INVALID_INPUT");

    const crossUserAnalysis = await invokeUser(userB, `analysis-get/${photoAnalysis.analysis_id}`, { method: "GET" });
    assertError(crossUserAnalysis, 404, "NOT_FOUND");
  });

  await t.test("insights, export, cleanup, and account deletion APIs", async () => {
    for (let index = 0; index < 3; index += 1) {
      const body = mealBody({
        title: `API E2E insight meal ${index}`,
        loggedAt: `2026-05-${18 + index}T07:30:00.000Z`,
        calories: 400 + index,
      });
      assertOk(await invokeUser(userA, "meals", { body }));
    }

    const insight = assertOk(await invokeService("weekly-insights-generate", {
      body: { user_id: userA.id, week_start: "2026-05-18" },
    }));
    assertResponseMatchesContract("weeklyInsightsGenerate", 200, insight);
    assert.equal(insight.weekly_insights.length, 6);

    const dueUser = await trackedUser("api-e2e-due", { profile: true, displayName: "API E2E Due" });
    assertOk(await invokeUser(dueUser, "meals", {
      body: mealBody({
        title: "API E2E due insight meal",
        loggedAt: "2026-05-25T07:30:00.000Z",
        calories: 350,
      }),
    }));
    const batchInsight = assertOk(await invokeService("weekly-insights-generate", {
      body: { week_start: "2026-05-25", limit: 10 },
    }));
    assert.equal(typeof batchInsight.processed_users, "number");
    assert.ok(batchInsight.processed_users >= 1);
    assert.ok(testUsers.has(dueUser.id));

    const fakeService = await invoke("weekly-insights-generate", {
      body: { user_id: userA.id, week_start: "2026-05-18" },
      apikey: anonKey,
      bearer: fakeServiceRoleJwt(),
    });
    assert.equal(fakeService.status, 401, JSON.stringify(fakeService.body));
    assert.ok(
      fakeService.body?.code === "AUTH_REQUIRED" || /Invalid JWT/i.test(String(fakeService.body?.msg)),
      JSON.stringify(fakeService.body),
    );

    const exportRequestId = crypto.randomUUID();
    const nutritionExport = assertOk(await invokeUser(userA, "exports-create", {
      headers: { "Idempotency-Key": exportRequestId },
      body: { client_request_id: exportRequestId, export_type: "nutrition_json" },
    }), 202);
    assertResponseMatchesContract("exportCreate", 202, nutritionExport);
    assert.equal(nutritionExport.export_request.status, "completed");
    assert.ok(nutritionExport.export_request.signed_url);
    assert.ok(nutritionExport.export_request.row_counts.meals >= 1);

    const exportPoll = assertOk(await invokeUser(userA, `exports-create/${nutritionExport.export_request.id}`, {
      method: "GET",
    }));
    assertResponseMatchesContract("exportGet", 200, exportPoll);
    assert.equal(exportPoll.export_request.id, nutritionExport.export_request.id);

    const exportReplay = assertOk(await invokeUser(userA, "exports-create", {
      headers: { "Idempotency-Key": exportRequestId },
      body: { client_request_id: exportRequestId, export_type: "nutrition_json" },
    }), 202);
    assert.equal(exportReplay.export_request.id, nutritionExport.export_request.id);

    const exportConflict = await invokeUser(userA, "exports-create", {
      headers: { "Idempotency-Key": exportRequestId },
      body: { client_request_id: exportRequestId, export_type: "journal_csv" },
    });
    assertError(exportConflict, 409, "IDEMPOTENCY_CONFLICT");

    const csvRequestId = crypto.randomUUID();
    const csvExport = assertOk(await invokeUser(userA, "exports-create", {
      headers: { "Idempotency-Key": csvRequestId },
      body: { client_request_id: csvRequestId, export_type: "journal_csv" },
    }), 202);
    assert.equal(csvExport.export_request.content_type, "text/csv");

    const { data: artifact, error: artifactError } = await admin.storage
      .from("exports-private")
      .download(nutritionExport.export_request.result_storage_path);
    if (artifactError) throw artifactError;
    assert.match(await artifact.text(), /API E2E/);

    const crossUserExport = await invokeUser(userB, `exports-create/${nutritionExport.export_request.id}`, {
      method: "GET",
    });
    assertError(crossUserExport, 404, "NOT_FOUND");

    const expiredExportPath = `${userA.id}/${crypto.randomUUID()}/expired.json`;
    await admin.storage
      .from("exports-private")
      .upload(expiredExportPath, new Blob(["{}"], { type: "application/json" }), {
        contentType: "application/json",
        upsert: true,
      });
    const { data: expiredExport, error: expiredExportError } = await admin.from("export_requests").insert({
      user_id: userA.id,
      client_request_id: crypto.randomUUID(),
      export_type: "nutrition_json",
      status: "completed",
      result_storage_bucket: "exports-private",
      result_storage_path: expiredExportPath,
      expires_at: "2020-01-01T00:00:00.000Z",
    }).select("id").single();
    if (expiredExportError) throw expiredExportError;

    const expiredAssetPath = `${userA.id}/${crypto.randomUUID()}.jpg`;
    const expiredThumbPath = `${userA.id}/${crypto.randomUUID()}.jpg`;
    await admin.storage.from("meal-originals-private").upload(expiredAssetPath, new Blob([onePixelJpeg], { type: "image/jpeg" }), {
      contentType: "image/jpeg",
      upsert: true,
    });
    await admin.storage.from("meal-thumbnails-private").upload(expiredThumbPath, new Blob([onePixelJpeg], { type: "image/jpeg" }), {
      contentType: "image/jpeg",
      upsert: true,
    });
    const { data: expiredAsset, error: expiredAssetError } = await admin.from("meal_assets").insert({
      user_id: userA.id,
      storage_bucket: "meal-originals-private",
      storage_path: expiredAssetPath,
      thumb_storage_path: expiredThumbPath,
      sha256: crypto.randomUUID().replaceAll("-", ""),
      mime_type: "image/jpeg",
      size_bytes: onePixelJpeg.length,
      retention_until: "2020-01-01T00:00:00.000Z",
    }).select("id").single();
    if (expiredAssetError) throw expiredAssetError;

    const cleanup = assertOk(await invokeService("media-retention-cleanup", { body: { limit: 100 } }));
    assert.ok(cleanup.export_cleanup.expired_requests >= 1);
    assert.ok(cleanup.media_cleanup.expired_assets >= 1);
    const { data: markedExport, error: markedExportError } = await admin
      .from("export_requests")
      .select("status,error_code")
      .eq("id", expiredExport.id)
      .single();
    if (markedExportError) throw markedExportError;
    assert.equal(markedExport.error_code, "EXPIRED");
    const { data: markedAsset, error: markedAssetError } = await admin
      .from("meal_assets")
      .select("deleted_at")
      .eq("id", expiredAsset.id)
      .single();
    if (markedAssetError) throw markedAssetError;
    assert.ok(markedAsset.deleted_at);

    const deleteUser = await trackedUser("api-e2e-delete", { profile: true, displayName: "API E2E Delete" });
    const nestedPath = `${deleteUser.id}/nested/${crypto.randomUUID()}.json`;
    await admin.storage
      .from("exports-private")
      .upload(nestedPath, new Blob(["{}"], { type: "application/json" }), {
        contentType: "application/json",
        upsert: true,
      });
    const invalidDelete = await invokeUser(deleteUser, "account-delete", {
      body: { confirmation: "WRONG" },
    });
    assertError(invalidDelete, 400, "INVALID_INPUT");
    const deletion = assertOk(await invokeUser(deleteUser, "account-delete", {
      body: { confirmation: "DELETE" },
    }));
    assertResponseMatchesContract("accountDelete", 200, deletion);
    assert.equal(deletion.account_deletion.status, "completed");
    testUsers.delete(deleteUser.id);

    const { data: deletedProfile, error: deletedProfileError } = await admin
      .from("profiles")
      .select("id")
      .eq("id", deleteUser.id)
      .maybeSingle();
    if (deletedProfileError) throw deletedProfileError;
    assert.equal(deletedProfile, null);
  });
});

async function trackedUser(prefix, options) {
  const user = await createSignedInUser(prefix, options);
  testUsers.add(user.id);
  return user;
}

function mealBody({ title, loggedAt = "2026-05-20T07:30:00.000Z", calories = 450 }) {
  return {
    client_request_id: crypto.randomUUID(),
    client_id: crypto.randomUUID(),
    title,
    meal_type: "lunch",
    source: "manual",
    logged_at: loggedAt,
    timezone: "Asia/Kolkata",
    items: [{
      client_id: crypto.randomUUID(),
      position: 0,
      name: title.includes("insight") ? "Roti" : "Dal",
      food_ref_kind: "manual",
      quantity: 1,
      unit: "serving",
      calories_kcal: calories,
      protein_g: 20,
      carbs_g: 50,
      fat_g: 10,
    }],
  };
}
