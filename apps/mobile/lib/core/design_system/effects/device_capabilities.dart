import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native device signals the design system adapts to.
class DeviceCapabilities {
  DeviceCapabilities._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'lowPowerModeChanged' && call.arguments is bool) {
        lowPowerMode.value = call.arguments as bool;
      }
    });
    _refresh();
  }

  static final DeviceCapabilities instance = DeviceCapabilities._();
  static const _channel = MethodChannel('snapgrub/device');

  /// iOS Low Power Mode / Android battery saver.
  final ValueNotifier<bool> lowPowerMode = ValueNotifier(false);

  Future<void> _refresh() async {
    try {
      final value = await _channel.invokeMethod<bool>('isLowPowerMode');
      lowPowerMode.value = value ?? false;
    } catch (_) {
      // Unsupported platform or tests: assume normal power.
    }
  }

  Future<bool> supportsAlternateIcons() async {
    try {
      return await _channel.invokeMethod<bool>('supportsAlternateIcons') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Pass null to restore the primary icon.
  Future<bool> setAlternateIcon(String? name) async {
    try {
      return await _channel
              .invokeMethod<bool>('setAlternateIcon', {'name': name}) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
