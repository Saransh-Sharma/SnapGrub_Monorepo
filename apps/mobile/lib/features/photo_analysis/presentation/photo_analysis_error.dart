import 'package:snapgrub/core/feedback/friendly_error.dart';

/// Photo-specific wording for analysis failures. Used by the photo analysis
/// screen and the pending photo card on Today so both say the same thing.
///
/// Analysis codes (`no_food`, `blurry`, …) and a missing backend get their own
/// copy. Offline and API errors go through the shared [friendlyError]; any
/// other failure reads as an unreadable photo.
FriendlyError photoAnalysisError(Object? error) {
  final text = (error?.toString() ?? '').toLowerCase();
  if (text.contains('no_food') || text.contains('not_food')) {
    return const FriendlyError(
      title: 'No food found',
      message: 'Try a clearer photo from above, or enter it manually.',
    );
  }
  if (text.contains('blur') ||
      text.contains('too_dark') ||
      text.contains('low_quality')) {
    return const FriendlyError(
      title: 'Photo is hard to read',
      message: 'Try again in better light.',
    );
  }
  if (text.contains('not configured')) {
    return const FriendlyError(
      title: 'Photo analysis unavailable',
      message: 'You can still enter this meal manually.',
      retryable: false,
    );
  }
  final shared = error == null ? null : friendlyError(error);
  if (shared != null &&
      (shared.offline || (error is! StateError && error is! String))) {
    return shared;
  }
  return const FriendlyError(
    title: 'Couldn’t read this photo',
    message: 'Try again or enter it manually.',
  );
}
