import 'package:flutter/services.dart';

const _channel = MethodChannel('snapgrub/ocr');

/// Runs fully on device: Apple Vision on iOS and ML Kit on Android.
Future<String> recognizeLabelText(String imagePath) async {
  final text = await _channel.invokeMethod<String>(
    'recognizeText',
    {'path': imagePath},
  );
  return text ?? '';
}
