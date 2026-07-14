class FeatureFlags {
  FeatureFlags(Map<String, Object?> values)
      : _values = Map.unmodifiable(values);

  final Map<String, Object?> _values;

  bool isEnabled(FeatureFlag flag) {
    final value = _values[flag.key];
    return value is bool ? value : flag.defaultEnabled;
  }
}

enum FeatureFlag {
  snapstrip('snapstrip.enabled'),
  photoAnalysis('photo_analysis.enabled'),
  barcode('barcode.enabled'),
  ocrAssist('ocr_assist.enabled'),
  voiceCapture('voice_capture.enabled'),
  smartFoodsV2('smart_foods_v2.enabled', defaultEnabled: false),
  weeklyInsights('weekly_insights.enabled', defaultEnabled: false);

  const FeatureFlag(this.key, {this.defaultEnabled = true});

  final String key;
  final bool defaultEnabled;
}
