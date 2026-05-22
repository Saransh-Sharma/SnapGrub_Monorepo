bool isConflictSyncError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('conflict') ||
      message.contains('409') ||
      message.contains('idempotency_conflict');
}

bool isRetryableSyncError(Object error) {
  final message = error.toString().toLowerCase();
  return !(message.contains('invalid_input') ||
      message.contains('auth_required') ||
      message.contains('not_found') ||
      message.contains('400') ||
      message.contains('401') ||
      message.contains('403') ||
      message.contains('404') ||
      isConflictSyncError(error));
}

class NonRetryableSyncException implements Exception {
  const NonRetryableSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
