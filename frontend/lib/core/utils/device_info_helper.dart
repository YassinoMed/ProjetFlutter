/// Device Info Helper — provides unique device identification
///
/// Uses device_info_plus to generate a stable device identifier
/// for trusted device management. This ID is NOT a fingerprint —
/// it's a hardware identifier used to correlate login sessions
/// with specific devices.
library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceInfoHelper {
  final DeviceInfoPlugin _deviceInfo;

  DeviceInfoHelper({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Get a stable, unique device identifier
  ///
  /// - iOS: identifierForVendor (resets on app reinstall)
  /// - Android: androidId (stable across reinstalls on most devices)
  Future<String> getDeviceId() async {
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios-unknown';
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    }
    return 'unknown-device';
  }

  /// Get a human-readable device name
  ///
  /// Examples: "iPhone 15 Pro", "Samsung Galaxy S24"
  Future<String> getDeviceName() async {
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.utsname.machine; // e.g. "iPhone16,1"
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      final brand = androidInfo.brand;
      final model = androidInfo.model;
      return '$brand $model';
    }
    return 'Unknown Device';
  }

  /// Get the platform string (ios / android)
  String getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Get all device info in one call (reduces platform calls)
  Future<({String deviceId, String deviceName, String platform})>
      getDeviceInfo() async {
    return (
      deviceId: await getDeviceId(),
      deviceName: await getDeviceName(),
      platform: getPlatform(),
    );
  }
}

// ── Provider ────────────────────────────────────────────────

final deviceInfoHelperProvider = Provider<DeviceInfoHelper>((ref) {
  return DeviceInfoHelper();
});
