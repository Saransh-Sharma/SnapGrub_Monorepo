class DeviceRegistration {
  const DeviceRegistration({
    required this.installId,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
  });

  final String installId;
  final String platform;
  final String appVersion;
  final String buildNumber;
}
