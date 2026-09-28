import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/core/design_system/haptics.dart';
import 'package:snapgrub/core/feedback/friendly_error.dart';
import 'package:snapgrub/features/conversation/data/conversation_remote_service.dart';
import 'package:snapgrub/core/feature_flags/feature_flags.dart';
import 'package:snapgrub/features/conversation/data/conversation_repository.dart';
import 'package:snapgrub/features/conversation/domain/conversation.dart';
import 'package:snapgrub/features/home/application/home_controller.dart';
import 'package:snapgrub/features/meal_editor/data/meal_repository.dart';
import 'package:snapgrub/features/meal_editor/domain/meal.dart';
import 'package:snapgrub/features/multimodal/data/multimodal_remote_service.dart';
import 'package:snapgrub/features/profile/application/profile_controller.dart';

final conversationControllerProvider =
    NotifierProvider<ConversationController, ConversationComposerState>(
  ConversationController.new,
);

class ConversationComposerState {
  const ConversationComposerState({
    this.isSending = false,
    this.activeDay,
    this.activity,
    this.streamingText = '',
    this.errorMessage,
  });

  final bool isSending;
  final DateTime? activeDay;
  final String? activity;
  final String streamingText;
  final String? errorMessage;

  ConversationComposerState copyWith({
    bool? isSending,
    DateTime? activeDay,
    String? activity,
    String? streamingText,
    String? errorMessage,
    bool clearActivity = false,
    bool clearError = false,
  }) =>
      ConversationComposerState(
        isSending: isSending ?? this.isSending,
        activeDay: activeDay ?? this.activeDay,
        activity: clearActivity ? null : activity ?? this.activity,
        streamingText: streamingText ?? this.streamingText,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

/// The meal a proposal wants to change is gone (deleted here or on another
/// device). [message] is written for people.
class ProposalTargetMissing implements Exception {
  const ProposalTargetMissing();

  String get message => 'That meal was already deleted.';

  @override
  String toString() => message;
}

class ConversationController extends Notifier<ConversationComposerState> {
  @override
  ConversationComposerState build() => const ConversationComposerState();

  Future<void> sendMessage(DateTime day, String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return;
    final userContext = await ref.read(homeUserContextProvider.future);
    final profileState = await ref.read(profileControllerProvider.future);
    final profile = profileState.profile;
    if (userContext == null || profile == null) return;

    final repository = ref.read(conversationRepositoryProvider);
    final thread = await repository.ensureThread(
      userId: userContext.userId,
      day: day,
      timezone: userContext.timezone,
    );
    final userMessage = await repository.addMessage(
      thread: thread,
      role: ThreadMessageRole.user,
      kind: ThreadMessageKind.text,
      text: text,
      deliveryState: MessageDeliveryState.pending,
    );

    state = const ConversationComposerState(
      isSending: true,
      activity: 'Checking your history…',
    ).copyWith(activeDay: day);
    try {
      MealDraft? draft;
      String assistantText = '';
      String? proposalId;
      var operation = ProposalOperation.create;
      String? targetMealId;
      int? expectedRevision;
      final remote = ref.read(conversationRemoteServiceProvider);
      final streamingEnabled = FeatureFlags(profileState.featureFlags)
          .isEnabled(FeatureFlag.agentStreaming);
      if (streamingEnabled && remote.isConfigured && !remote.e2eMock) {
        await for (final event in remote.run(
          thread: thread,
          clientRequestId: userMessage.clientId,
          message: text,
          locale: profile.locale,
          cuisineHints: profile.cuisinePreferences,
        )) {
          switch (event.event) {
            case 'assistant.delta':
              assistantText += event.data['text'] as String? ?? '';
              state = state.copyWith(
                streamingText: assistantText,
                clearActivity: true,
              );
            case 'tool.started':
              state = state.copyWith(
                activity: event.data['label'] as String? ??
                    'Checking your history…',
              );
            case 'proposal.ready':
              final rawDraft = event.data['draft'];
              if (rawDraft is Map) {
                draft = mealDraftFromJson(Map<String, dynamic>.from(rawDraft));
              }
              proposalId = event.data['proposal_id'] as String?;
              final operationName = event.data['operation'] as String?;
              if (operationName != null) {
                operation = ProposalOperation.values.byName(operationName);
              }
              targetMealId = event.data['target_meal_id'] as String?;
              expectedRevision =
                  (event.data['expected_revision'] as num?)?.toInt();
            case 'run.failed':
              throw StateError(event.data['message'] as String? ??
                  'Couldn’t finish that. Try again.');
          }
        }
      } else {
        draft = await ref.read(multimodalRemoteServiceProvider).parseText(
              userId: userContext.userId,
              profile: profile,
              text: text,
            );
      }

      if (draft != null) {
        _placeDraftOnDay(draft, day);
        final message = await repository.addMessage(
          thread: thread,
          role: ThreadMessageRole.assistant,
          kind: ThreadMessageKind.text,
          text: assistantText.trim().isEmpty
              ? _proposalCopy(draft)
              : assistantText.trim(),
        );
        await repository.stageProposal(
          thread: thread,
          draft: draft,
          messageId: message.id,
          id: proposalId,
          operation: operation,
          targetMealId: targetMealId,
          expectedRevision: expectedRevision,
        );
      } else if (assistantText.trim().isNotEmpty) {
        await repository.addMessage(
          thread: thread,
          role: ThreadMessageRole.assistant,
          kind: ThreadMessageKind.text,
          text: assistantText.trim(),
        );
      }
      if (streamingEnabled && remote.isConfigured && !remote.e2eMock) {
        await repository.markMessageDelivered(userMessage);
      }
      state = const ConversationComposerState();
      unawaited(SgHaptics.tick());
    } catch (error) {
      final message = _assistantError(error);
      await repository.addMessage(
        thread: thread,
        role: ThreadMessageRole.assistant,
        kind: ThreadMessageKind.error,
        text: message,
        deliveryState: MessageDeliveryState.failed,
      );
      state = ConversationComposerState(errorMessage: message);
    }
  }

  Future<Meal?> confirmProposal(MealChangeProposal proposal) async {
    final meals = ref.read(mealRepositoryProvider);
    Meal? meal;
    switch (proposal.operation) {
      case ProposalOperation.create:
        meal = await meals.saveDraft(proposal.draft);
      case ProposalOperation.update:
        if (proposal.targetMealId == null) {
          throw const ProposalTargetMissing();
        }
        final payload = mealDraftToJson(proposal.draft)
          ..['id'] = proposal.targetMealId
          ..['expected_revision'] = proposal.expectedRevision;
        meal = await meals.saveDraft(
          mealDraftFromJson(Map<String, dynamic>.from(payload)),
        );
      case ProposalOperation.delete:
        final target = proposal.targetMealId == null
            ? null
            : await meals.getMeal(proposal.targetMealId!);
        if (target == null) {
          throw const ProposalTargetMissing();
        }
        await meals.deleteMeal(target);
    }
    await ref
        .read(conversationRepositoryProvider)
        .setProposalStatus(proposal, ProposalStatus.confirmed);
    final profileState = await ref.read(profileControllerProvider.future);
    final timezone = profileState.profile?.timezone ?? proposal.draft.timezone;
    final thread = await ref.read(conversationRepositoryProvider).ensureThread(
          userId: proposal.userId,
          day: proposal.draft.loggedAt,
          timezone: timezone,
        );
    await ref.read(conversationRepositoryProvider).addMessage(
          thread: thread,
          role: ThreadMessageRole.assistant,
          kind: ThreadMessageKind.activity,
          text: switch (proposal.operation) {
            ProposalOperation.create => 'Logged. Tap it to edit.',
            ProposalOperation.update => 'Updated.',
            ProposalOperation.delete => 'Deleted.',
          },
        );
    unawaited(SgHaptics.logged());
    return meal;
  }

  Future<void> rejectProposal(MealChangeProposal proposal) async {
    await ref
        .read(conversationRepositoryProvider)
        .setProposalStatus(proposal, ProposalStatus.rejected);
    unawaited(SgHaptics.tick());
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _placeDraftOnDay(MealDraft draft, DateTime day) {
    final now = DateTime.now();
    draft.loggedAt =
        DateTime(day.year, day.month, day.day, now.hour, now.minute);
  }

  String _proposalCopy(MealDraft draft) {
    final itemCount = draft.items.length;
    return itemCount == 1
        ? 'Found 1 item. Check it before I log it.'
        : 'Found $itemCount items. Check them before I log it.';
  }

  /// Assistant-voice copy for a failed run. Offline comes from the shared
  /// [friendlyError] classifier (socket, client and timeout errors), not from
  /// words in our own messages, so "The assistant isn’t available right now."
  /// is never mistaken for offline.
  String _assistantError(Object error) {
    if (friendlyError(error).offline) {
      return 'You’re offline. Your message is saved. Send it when you’re back.';
    }
    if (error.toString().toLowerCase().contains('could not identify')) {
      return 'I couldn’t find a food in that. Add an amount, or enter it manually.';
    }
    return 'Couldn’t finish that. Try again, or enter it manually.';
  }
}
