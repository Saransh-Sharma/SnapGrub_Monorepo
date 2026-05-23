import 'package:snapgrub_api_contracts/snapgrub_api_contracts.dart';

class SnapGrubApiException implements Exception {
  const SnapGrubApiException({
    required this.status,
    required this.code,
    required this.message,
    required this.userMessage,
    required this.retryable,
    required this.requestId,
    this.details = const {},
  });

  final int status;
  final String code;
  final String message;
  final String userMessage;
  final bool retryable;
  final String requestId;
  final JsonMap details;

  factory SnapGrubApiException.fromEnvelope(
    ErrorEnvelope envelope, {
    required int status,
  }) {
    return SnapGrubApiException(
      status: status,
      code: envelope.code,
      message: envelope.message,
      userMessage: envelope.userMessage,
      retryable: envelope.retryable,
      requestId: envelope.requestId,
      details: envelope.details,
    );
  }

  @override
  String toString() => userMessage;
}
