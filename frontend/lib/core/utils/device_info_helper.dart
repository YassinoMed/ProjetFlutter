/// Device Info Helper — provides a stable applicative device identifier
///
/// IMPORTANT: The device_id is an applicative UUID generated once and stored
/// in flutter_secure_storage. It is NOT a hardware ID. It persists across
/// app restarts but NOT across reinstalls, which is the correct behavior:
/// a reinstalled app = a new device from a trust perspective.
library;

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../security/secure_storage_service.dart';

class DeviceInfoHelper {
  final SecureStorageService _secureStorage;
  final DeviceInfoPlugin _deviceInfo;

  DeviceInfoHelper({
    required SecureStorageService secureStorage,
    DeviceInfoPlugin? deviceInfo,
  })  : _secureStorage = secureStorage,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Get (or generate) a stable applicative device identifier.
  ///
  /// This is a UUID stored in SecureStorage, not a hardware ID.
  /// It survives app restarts but not reinstalls.
  Future<String> getDeviceId() async {
    // Check if we already have one
    String? deviceId = await _secureStorage.read(
      key: AppConstants.keyBiometricDeviceId,
    );

    if (deviceId == null || deviceId.isEmpty) {
      // Generate a new UUID
      deviceId = const Uuid().v4();
      await _secureStorage.write(
        key: AppConstants.keyBiometricDeviceId,
        value: deviceId,
      );
    }

    return deviceId;
  }

  /// Get a human-readable device name (for display in "trusted devices" list).
  ///
  /// Examples: "iPhone16,1", "Samsung Galaxy S24"
  Future<String> getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.utsname.machine; // e.g. "iPhone16,1"
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final brand = androidInfo.brand;
        final model = androidInfo.model;
        return '$brand $model';
      }
    } catch (_) {}
    return 'Unknown Device';
  }

  /// Get the platform string.
  String getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Get all device info in one call.
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
  return DeviceInfoHelper(
    secureStorage: ref.watch(secureStorageProvider),
  );
});
