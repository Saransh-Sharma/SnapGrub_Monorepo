import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';

void main() {
  test('agent stream event preserves ordered envelope fields', () {
    final event = AgentStreamEvent.fromJson({
      'event': 'proposal.ready',
      'run_id': 'run-1',
      'sequence': 8,
      'message_id': 'message-1',
      'data': {
        'proposal_id': 'proposal-1',
        'draft': {'title': 'Breakfast'},
      },
    });

    expect(event.event, 'proposal.ready');
    expect(event.runId, 'run-1');
    expect(event.sequence, 8);
    expect(event.messageId, 'message-1');
    expect(event.data['proposal_id'], 'proposal-1');
  });

  test('meal proposal draft survives local persistence round trip', () {
    final original = MealDraft(
      id: 'meal-1',
      clientId: 'meal-client-1',
      userId: 'user-1',
      timezone: 'Asia/Kolkata',
      title: 'Masala omelette and toast',
      mealType: MealType.breakfast,
      source: MealSource.text,
      loggedAt: DateTime.parse('2026-07-14T08:15:00+05:30'),
      confidenceOverall: .84,
      provenanceType: 'conversation_agent',
      items: [
        MealDraftItem(
          id: 'item-1',
          clientId: 'item-client-1',
          name: 'Masala omelette',
          quantity: 1,
          unit: 'serving',
          caloriesKcal: 240,
          proteinG: 15,
          carbsG: 6,
          fatG: 17,
        ),
      ],
    );

    final restored = decodeDraft(encodeDraft(original));

    expect(restored.id, original.id);
    expect(restored.clientId, original.clientId);
    expect(restored.loggedAt.toUtc(), original.loggedAt.toUtc());
    expect(restored.mealType, MealType.breakfast);
    expect(restored.source, MealSource.text);
    expect(restored.items.single.name, 'Masala omelette');
    expect(restored.caloriesKcal, 240);
  });

  test('malformed optional stream fields degrade without losing run failure',
      () {
    final event = AgentStreamEvent.fromJson(const {'data': {}});

    expect(event.event, 'run.failed');
    expect(event.runId, isEmpty);
    expect(event.sequence, 0);
  });
}
