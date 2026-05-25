/// On-device label OCR. ML Kit is the normal app implementation; the iOS
/// simulator E2E runner swaps this facade to the stub before `pod install`.
library;

export 'label_text_recognizer_mlkit.dart';
