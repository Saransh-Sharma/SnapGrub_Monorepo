/// A capture failure whose [message] is written for people and can be shown
/// as-is (see docs/09-design/voice.md).
class CaptureException implements Exception {
  const CaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}
