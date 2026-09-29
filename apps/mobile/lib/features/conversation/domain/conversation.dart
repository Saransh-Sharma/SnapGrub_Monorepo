import 'dart:convert';

import 'package:snapgrub/features/meal_editor/domain/meal.dart';

enum ThreadMessageRole { user, assistant, system, tool }

enum ThreadMessageKind { text, activity, mealProposal, mealEvent, error }

enum MessageDeliveryState { pending, streaming, delivered, queued, failed }

enum ProposalOperation { create, update, delete }

enum ProposalStatus { pending, confirmed, edited, rejected, undone, expired }

class DailyThread {
  const DailyThread({
    required this.id,
    required this.userId,
    required this.day,
    required this.timezone,
  });

  final String id;
  final String userId;
  final DateTime day;
  final String timezone;
}

class ThreadMessage {
  const ThreadMessage({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.clientId,
    required this.role,
    required this.kind,
    required this.sequence,
    required this.deliveryState,
    required this.createdAt,
    this.text,
    this.payload = const {},
  });

  final String id;
  final String threadId;
  final String userId;
  final String clientId;
  final ThreadMessageRole role;
  final ThreadMessageKind kind;
  final String? text;
  final Map<String, Object?> payload;
  final int sequence;
  final MessageDeliveryState deliveryState;
  final DateTime createdAt;
}

class MealChangeProposal {
  const MealChangeProposal({
    required this.id,
    required this.threadId,
    required this.userId,
    required this.operation,
    required this.draft,
    required this.status,
    required this.createdAt,
    this.messageId,
    this.targetMealId,
    this.expectedRevision,
  });

  final String id;
  final String threadId;
  final String userId;
  final String? messageId;
  final ProposalOperation operation;
  final String? targetMealId;
  final int? expectedRevision;
  final MealDraft draft;
  final ProposalStatus status;
  final DateTime createdAt;
}

class AgentStreamEvent {
  const AgentStreamEvent({
    required this.event,
    required this.runId,
    required this.sequence,
    required this.data,
    this.messageId,
  });

  final String event;
  final String runId;
  final int sequence;
  final String? messageId;
  final Map<String, Object?> data;

  factory AgentStreamEvent.fromJson(Map<String, dynamic> json) {
    return AgentStreamEvent(
      event: json['event'] as String? ?? 'run.failed',
      runId: json['run_id'] as String? ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      messageId: json['message_id'] as String?,
      data: Map<String, Object?>.from(json['data'] as Map? ?? const {}),
    );
  }
}

Map<String, Object?> mealDraftToJson(MealDraft draft) => {
      'id': draft.id,
      'user_id': draft.userId,
      'client_id': draft.clientId,
      'title': draft.title,
      'meal_type': draft.mealType.name,
      'source': draft.source.name,
      'logged_at': draft.loggedAt.toIso8601String(),
      'timezone': draft.timezone,
      'expected_revision': draft.expectedRevision,
      'confidence_overall': draft.confidenceOverall,
      'provenance_type': draft.provenanceType,
      'analysis_job_id': draft.analysisJobId,
      'photo_asset_id': draft.photoAssetId,
      'analysis_warnings': draft.analysisWarnings,
      'items': draft.items
          .map((item) => {
                'id': item.id,
                'client_id': item.clientId,
                'name': item.name,
                'food_ref_kind': item.foodRefKind,
                'canonical_food_id': item.canonicalFoodId,
                'branded_product_id': item.brandedProductId,
                'custom_food_id': item.customFoodId,
                'quantity': item.quantity,
                'unit': item.unit,
                'grams_estimated': item.gramsEstimated,
                'calories_kcal': item.caloriesKcal,
                'protein_g': item.proteinG,
                'carbs_g': item.carbsG,
                'fat_g': item.fatG,
                'confidence': item.confidence,
                'source_type': item.sourceType,
                'source_id': item.sourceId,
                'notes': item.notes,
              })
          .toList(),
    };

MealDraft mealDraftFromJson(Map<String, dynamic> json) => MealDraft(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      clientId: json['client_id'] as String?,
      title: json['title'] as String? ?? '',
      mealType:
          MealType.values.byName(json['meal_type'] as String? ?? 'unknown'),
      source: MealSource.values.byName(json['source'] as String? ?? 'manual'),
      loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? ''),
      timezone: json['timezone'] as String? ?? 'UTC',
      expectedRevision: (json['expected_revision'] as num?)?.toInt(),
      confidenceOverall: (json['confidence_overall'] as num?)?.toDouble(),
      provenanceType: json['provenance_type'] as String?,
      analysisJobId: json['analysis_job_id'] as String?,
      photoAssetId: json['photo_asset_id'] as String?,
      analysisWarnings:
          List<String>.from(json['analysis_warnings'] as List? ?? const []),
      items: (json['items'] as List? ?? const []).map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        return MealDraftItem(
          id: item['id'] as String?,
          clientId: item['client_id'] as String?,
          name: item['name'] as String? ?? '',
          foodRefKind: item['food_ref_kind'] as String? ?? 'manual',
          canonicalFoodId: item['canonical_food_id'] as String?,
          brandedProductId: item['branded_product_id'] as String?,
          customFoodId: item['custom_food_id'] as String?,
          quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
          unit: item['unit'] as String? ?? 'serving',
          gramsEstimated: (item['grams_estimated'] as num?)?.toDouble(),
          caloriesKcal: (item['calories_kcal'] as num?)?.toDouble() ?? 0,
          proteinG: (item['protein_g'] as num?)?.toDouble() ?? 0,
          carbsG: (item['carbs_g'] as num?)?.toDouble() ?? 0,
          fatG: (item['fat_g'] as num?)?.toDouble() ?? 0,
          confidence: (item['confidence'] as num?)?.toDouble(),
          sourceType: item['source_type'] as String?,
          sourceId: item['source_id'] as String?,
          notes: item['notes'] as String?,
        );
      }).toList(),
    );

String encodeDraft(MealDraft draft) => jsonEncode(mealDraftToJson(draft));

MealDraft decodeDraft(String value) =>
    mealDraftFromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
