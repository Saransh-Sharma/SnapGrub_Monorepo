export type AgentEvent = Record<string, unknown>;

export type ProposalEventInput = {
  proposalId: string;
  draft: Record<string, unknown>;
  operation: "create" | "update" | "delete";
  targetMealId: string | null;
  expectedRevision: number | null;
};

/// The event stream for a finished run. A run without a proposal is a plain
/// assistant reply, such as a clarifying question.
export function buildRunEvents(input: {
  runId: string;
  assistantId: string;
  assistantText: string;
  proposal: ProposalEventInput | null;
}): AgentEvent[] {
  const chunks = input.assistantText.match(/.{1,28}(?:\s|$)/g) ??
    [input.assistantText];
  const events: AgentEvent[] = [
    agentEvent("run.started", input.runId, 1, { status: "streaming" }),
    agentEvent("tool.started", input.runId, 2, {
      tool: "nutrition_lookup",
      label: "Checking your usual foods…",
    }),
    agentEvent("tool.completed", input.runId, 3, { tool: "nutrition_lookup" }),
  ];
  let sequence = 4;
  for (const chunk of chunks) {
    events.push(
      agentEvent(
        "assistant.delta",
        input.runId,
        sequence++,
        { text: chunk },
        input.assistantId,
      ),
    );
  }
  if (input.proposal) {
    events.push(agentEvent("proposal.ready", input.runId, sequence++, {
      proposal_id: input.proposal.proposalId,
      draft: input.proposal.draft,
      operation: input.proposal.operation,
      target_meal_id: input.proposal.targetMealId,
      expected_revision: input.proposal.expectedRevision,
    }, input.assistantId));
  }
  events.push(
    agentEvent(
      "run.completed",
      input.runId,
      sequence,
      { status: "completed" },
      input.assistantId,
    ),
  );
  return events;
}

export function agentEvent(
  type: string,
  runId: string,
  sequence: number,
  data: Record<string, unknown>,
  messageId?: string,
): AgentEvent {
  return {
    event: type,
    run_id: runId,
    sequence,
    ...(messageId ? { message_id: messageId } : {}),
    data,
  };
}
