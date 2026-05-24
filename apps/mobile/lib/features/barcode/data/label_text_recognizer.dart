/// On-device label OCR. ML Kit implementation lives in a separate library so
/// iOS E2E simulator builds can omit the google_mlkit plugin (no arm64 sim).
library;

export 'label_text_recognizer_mlkit.dart';
