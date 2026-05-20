class BodyMeasurement {
  const BodyMeasurement({
    required this.measuredAt,
    this.weightKg,
    this.bodyFatPct,
    this.source = 'manual',
  });

  final DateTime measuredAt;
  final double? weightKg;
  final double? bodyFatPct;
  final String source;
}
