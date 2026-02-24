/// Secure Storage Service - flutter_secure_storage wrapper
/// CDC page 16: Stockage sécurisé Keychain/Keystore
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<bool> containsKey({required String key}) async {
    return _storage.containsKey(key: key);
  }

  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }
}

// ── Provider ────────────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
