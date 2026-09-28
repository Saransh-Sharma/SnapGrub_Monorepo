import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snapgrub/features/photo_analysis/presentation/photo_analysis_error.dart';

/// The Today pending-photo card and the photo analysis screen share this
/// mapping, so a failed photo reads the same in both places.
void main() {
  test('analysis codes get photo-specific copy', () {
    expect(photoAnalysisError(StateError('no_food')).title, 'No food found');
    expect(photoAnalysisError(StateError('image_blurry')).title,
        'Photo is hard to read');
    final unavailable =
        photoAnalysisError(StateError('Supabase is not configured.'));
    expect(unavailable.title, 'Photo analysis unavailable');
    expect(unavailable.retryable, isFalse);
  });

  test('offline errors keep the shared offline copy', () {
    final error = photoAnalysisError(const SocketException('Failed host lookup'));
    expect(error.offline, isTrue);
    expect(error.title, 'You’re offline');
  });

  test('unknown failures read as an unreadable photo', () {
    expect(photoAnalysisError(null).title, 'Couldn’t read this photo');
    expect(photoAnalysisError(StateError('analysis_failed')).message,
        'Try again or enter it manually.');
  });
}
