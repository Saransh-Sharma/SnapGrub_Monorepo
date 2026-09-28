import { corsHeaders, jsonResponse, optionsResponse } from "../_shared/cors.ts";
import { createConversationProposal } from "../_shared/conversation_agent.ts";
import { ApiError, errorBody } from "../_shared/errors.ts";
import { consumeRateLimit } from "../_shared/rate_limit.ts";
import { requireUser, serviceClient } from "../_shared/supabase.ts";
import { optionalString, requireString } from "../_shared/validation.ts";

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID();
  if (req.method === "OPTIONS") return optionsResponse();
  try {
    const user = await requireUser(req);
    const client = serviceClient();
    const runId = idFromPath(new URL(req.url).pathname);
    if (req.method === "GET" && runId) {
      return jsonResponse(
        await replayPayload(client, user.id, runId, requestId),
      );
    }
    if (req.method !== "POST") {
      throw new ApiError("INVALID_INPUT", "Method not allowed", 405, false);
    }
    const body = await req.json().catch(() => {
      throw new ApiError(
        "INVALID_INPUT",
        "Request body must be valid JSON",
        400,
        false,
      );
    }) as Record<string, unknown>;
    const clientRequestId = requireString(
      body.client_request_id,
      "client_request_id",
    );
    const messageText = requireString(body.message, "message");
    const day = requireString(body.day, "day");
    const timezone = requireString(body.timezone, "timezone");
    const locale = requireString(body.locale, "locale");
    const requestedThreadId = optionalString(body.thread_id);

    const existing = await client.from("agent_runs").select("*")
      .eq("user_id", user.id).eq("client_request_id", clientRequestId)
      .maybeSingle();
    if (existing.error) throw existing.error;
    if (existing.data) {
      const replay = await eventsForRun(
        client,
        user.id,
        String(existing.data.id),
      );
      return sseResponse(replay);
    }
    await consumeRateLimit(client, user.id, "agent:runs", 60 * 60, 120);

    const thread = await ensureThread(
      client,
      user.id,
      requestedThreadId,
      day,
      timezone,
    );
    const userSequence = await nextSequence(client, String(thread.id));
    const userMessageId = crypto.randomUUID();
    const insertedMessage = await client.from("thread_messages").upsert({
      id: userMessageId,
      thread_id: thread.id,
      user_id: user.id,
      client_id: clientRequestId,
      role: "user",
      kind: "text",
      text_content: messageText,
      sequence: userSequence,
      delivery_state: "delivered",
    }, { onConflict: "user_id,client_id" }).select().single();
    if (insertedMessage.error) throw insertedMessage.error;

    const runInsert = await client.from("agent_runs").insert({
      thread_id: thread.id,
      user_id: user.id,
      client_request_id: clientRequestId,
      status: "streaming",
      redacted_metadata: {
        message_length: messageText.length,
        day,
        locale,
      },
    }).select().single();
    if (runInsert.error) throw runInsert.error;
    const run = runInsert.data;
    const startedAt = performance.now();

    try {
      const [dayMeals, recentMeals, goal] = await Promise.all([
        client.rpc("list_user_meals_for_day", {
          p_user_id: user.id,
          p_day: day,
          p_limit: 100,
        }),
        client.from("meals").select("title,meal_type,calories_kcal")
          .eq("user_id", user.id).is("deleted_at", null)
          .order("logged_at", { ascending: false }).limit(12),
        client.from("nutrition_goals").select("calories_kcal")
          .eq("user_id", user.id).eq("is_active", true).maybeSingle(),
      ]);
      const agent = await createConversationProposal({
        message: messageText,
        timezone,
        locale,
        cuisineHints: Array.isArray(body.cuisine_hints)
          ? body.cuisine_hints.map(String)
          : [],
        mealTypeHint: optionalString(body.meal_type_hint),
        dayMeals: dayMeals.data ?? [],
        recentMeals: recentMeals.data ?? [],
        calorieGoal: Number(goal.data?.calories_kcal) || null,
      });
      const assistantSequence = await nextSequence(client, String(thread.id));
      const assistantId = crypto.randomUUID();
      const assistantInsert = await client.from("thread_messages").insert({
        id: assistantId,
        thread_id: thread.id,
        user_id: user.id,
        client_id: crypto.randomUUID(),
        role: "assistant",
        kind: "text",
        text_content: agent.assistantText,
        sequence: assistantSequence,
        delivery_state: "delivered",
      });
      if (assistantInsert.error) throw assistantInsert.error;
      const proposalId = crypto.randomUUID();
      const mobileDraft = mobileDraftPayload(
        agent.draft,
        user.id,
        day,
        timezone,
        agent.targetMealId,
        agent.expectedRevision,
      );
      const proposalInsert = await client.from("meal_change_proposals").insert({
        id: proposalId,
        thread_id: thread.id,
        user_id: user.id,
        agent_run_id: run.id,
        message_id: assistantId,
        operation: agent.operation,
        target_meal_id: agent.targetMealId,
        expected_revision: agent.expectedRevision,
        draft_payload: mobileDraft,
        status: "pending",
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
          .toISOString(),
      });
      if (proposalInsert.error) throw proposalInsert.error;
      const latencyMs = Math.round(performance.now() - startedAt);
      const completed = await client.from("agent_runs").update({
        status: "completed",
        provider: agent.provider,
        model_name: agent.model,
        input_tokens: agent.inputTokens,
        output_tokens: agent.outputTokens,
        latency_ms: latencyMs,
        cursor: 6,
        completed_at: new Date().toISOString(),
      }).eq("id", run.id);
      if (completed.error) throw completed.error;
      return sseResponse(buildEvents({
        runId: String(run.id),
        assistantId,
        assistantText: agent.assistantText,
        proposalId,
        draft: mobileDraft,
        operation: agent.operation,
        targetMealId: agent.targetMealId,
        expectedRevision: agent.expectedRevision,
      }));
    } catch (error) {
      await client.from("agent_runs").update({
        status: "failed",
        error_code: error instanceof ApiError ? error.code : "UNKNOWN",
        latency_ms: Math.round(performance.now() - startedAt),
        completed_at: new Date().toISOString(),
      }).eq("id", run.id);
      throw error;
    }
  } catch (error) {
    const status = error instanceof ApiError ? error.status : 500;
    return jsonResponse(errorBody(error, requestId), status);
  }
});

function sseResponse(events: Record<string, unknown>[]) {
  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      for (const event of events) {
        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify(event)}\n\n`),
        );
        await new Promise((resolve) => setTimeout(resolve, 18));
      }
      controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      controller.close();
    },
  });
  return new Response(stream, {
    headers: {
      ...corsHeaders,
      "content-type": "text/event-stream; charset=utf-8",
      "cache-control": "no-cache, no-transform",
      connection: "keep-alive",
    },
  });
}

function buildEvents(input: {
  runId: string;
  assistantId: string;
  assistantText: string;
  proposalId: string;
  draft: Record<string, unknown>;
  operation: "create" | "update" | "delete";
  targetMealId: string | null;
  expectedRevision: number | null;
}) {
  const chunks = input.assistantText.match(/.{1,28}(?:\s|$)/g) ??
    [input.assistantText];
  const events: Record<string, unknown>[] = [
    event("run.started", input.runId, 1, { status: "streaming" }),
    event("tool.started", input.runId, 2, {
      tool: "nutrition_lookup",
      label: "Checking your usual foods…",
    }),
    event("tool.completed", input.runId, 3, { tool: "nutrition_lookup" }),
  ];
  let sequence = 4;
  for (const chunk of chunks) {
    events.push(
      event(
        "assistant.delta",
        input.runId,
        sequence++,
        { text: chunk },
        input.assistantId,
      ),
    );
  }
  events.push(event("proposal.ready", input.runId, sequence++, {
    proposal_id: input.proposalId,
    draft: input.draft,
    operation: input.operation,
    target_meal_id: input.targetMealId,
    expected_revision: input.expectedRevision,
  }, input.assistantId));
  events.push(
    event(
      "run.completed",
      input.runId,
      sequence,
      { status: "completed" },
      input.assistantId,
    ),
  );
  return events;
}

function event(
  type: string,
  runId: string,
  sequence: number,
  data: Record<string, unknown>,
  messageId?: string,
) {
  return {
    event: type,
    run_id: runId,
    sequence,
    ...(messageId ? { message_id: messageId } : {}),
    data,
  };
}

async function ensureThread(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  requestedId: string | null,
  day: string,
  timezone: string,
) {
  const result = await client.from("daily_threads").upsert({
    id: requestedId ?? crypto.randomUUID(),
    user_id: userId,
    day,
    timezone,
  }, { onConflict: "user_id,day" }).select().single();
  if (result.error) throw result.error;
  return result.data;
}

async function nextSequence(
  client: ReturnType<typeof serviceClient>,
  threadId: string,
) {
  const result = await client.from("thread_messages").select("sequence")
    .eq("thread_id", threadId).order("sequence", { ascending: false }).limit(1)
    .maybeSingle();
  if (result.error) throw result.error;
  return Number(result.data?.sequence ?? 0) + 1;
}

function mobileDraftPayload(
  draft: Awaited<ReturnType<typeof createConversationProposal>>["draft"],
  userId: string,
  day: string,
  timezone: string,
  targetMealId: string | null,
  expectedRevision: number | null,
) {
  const now = new Date();
  const time = `${now.getUTCHours().toString().padStart(2, "0")}:${
    now.getUTCMinutes().toString().padStart(2, "0")
  }:00.000Z`;
  return {
    id: targetMealId ?? crypto.randomUUID(),
    user_id: userId,
    client_id: crypto.randomUUID(),
    title: draft.title,
    meal_type: draft.meal_type,
    source: "text",
    logged_at: `${day}T${time}`,
    timezone,
    expected_revision: expectedRevision,
    confidence_overall: draft.confidence.overall,
    provenance_type: "conversation_agent",
    analysis_warnings: draft.confidence.warnings.map((item) => item.message),
    items: draft.components.map((item) => ({
      id: crypto.randomUUID(),
      client_id: item.client_id || crypto.randomUUID(),
      name: item.name,
      food_ref_kind: item.food_ref_kind,
      canonical_food_id: item.canonical_food_id,
      branded_product_id: item.branded_product_id,
      custom_food_id: item.custom_food_id,
      quantity: item.quantity,
      unit: item.unit,
      grams_estimated: item.grams_estimated,
      calories_kcal: item.calories_kcal,
      protein_g: item.protein_g,
      carbs_g: item.carbs_g,
      fat_g: item.fat_g,
      confidence: item.confidence,
      source_type: item.source_type,
      source_id: item.source_id,
      notes: item.notes,
    })),
  };
}

async function eventsForRun(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  runId: string,
) {
  const run = await client.from("agent_runs").select("*").eq("id", runId)
    .eq("user_id", userId).single();
  if (run.error) throw run.error;
  const proposal = await client.from("meal_change_proposals").select("*")
    .eq("agent_run_id", runId).eq("user_id", userId).maybeSingle();
  if (proposal.error) throw proposal.error;
  if (!proposal.data) {
    return [
      event("run.failed", runId, 1, { message: "This run has no proposal." }),
    ];
  }
  const message = await client.from("thread_messages").select("*")
    .eq("id", proposal.data.message_id).single();
  if (message.error) throw message.error;
  return buildEvents({
    runId,
    assistantId: String(message.data.id),
    assistantText: String(message.data.text_content ?? ""),
    proposalId: String(proposal.data.id),
    draft: proposal.data.draft_payload as Record<string, unknown>,
    operation: proposal.data.operation,
    targetMealId: proposal.data.target_meal_id,
    expectedRevision: proposal.data.expected_revision,
  });
}

async function replayPayload(
  client: ReturnType<typeof serviceClient>,
  userId: string,
  runId: string,
  requestId: string,
) {
  const run = await client.from("agent_runs").select("*").eq("id", runId)
    .eq("user_id", userId).maybeSingle();
  if (run.error) throw run.error;
  if (!run.data) {
    throw new ApiError("NOT_FOUND", "Agent run not found", 404, false);
  }
  const [thread, messages] = await Promise.all([
    client.from("daily_threads").select("*").eq("id", run.data.thread_id)
      .eq("user_id", userId).single(),
    client.from("thread_messages").select("*").eq(
      "thread_id",
      run.data.thread_id,
    ).eq("user_id", userId).order("sequence"),
  ]);
  if (thread.error) throw thread.error;
  if (messages.error) throw messages.error;
  return {
    agent_run: run.data,
    thread: thread.data,
    messages: messages.data ?? [],
    events: await eventsForRun(client, userId, runId),
    request_id: requestId,
    server_time: new Date().toISOString(),
  };
}

function idFromPath(pathname: string) {
  const parts = pathname.split("/").filter(Boolean);
  const index = parts.lastIndexOf("agent-runs");
  return index >= 0 && parts.length > index + 1 ? parts[index + 1] : null;
}
