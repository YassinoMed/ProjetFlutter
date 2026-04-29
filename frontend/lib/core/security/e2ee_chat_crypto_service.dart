import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediconnect_pro/core/constants/api_constants.dart';
import 'package:mediconnect_pro/core/constants/app_constants.dart';
import 'package:mediconnect_pro/core/network/api_response.dart';
import 'package:mediconnect_pro/core/security/encryption_service.dart';
import 'package:mediconnect_pro/core/security/secure_storage_service.dart';
import 'package:mediconnect_pro/core/utils/device_info_helper.dart';
import 'package:pointycastle/export.dart';

class E2eeUnavailableException implements Exception {
  final String message;

  const E2eeUnavailableException(this.message);

  @override
  String toString() => message;
}

class EncryptedChatPayload {
  final String ciphertext;
  final String nonce;
  final String algorithm;
  final String keyId;

  const EncryptedChatPayload({
    required this.ciphertext,
    required this.nonce,
    required this.algorithm,
    required this.keyId,
  });
}

class E2eeChatCryptoService {
  static const String algorithm = 'P-256-ECDH-AES-256-GCM';
  static const String _bundleVersion = '1';
  static const String _keyId = 'identity-v1';
  static const String _encryptedUnavailableLabel =
      'Message chiffré indisponible sur cet appareil';

  final SecureStorageService secureStorage;
  final DeviceInfoHelper deviceInfoHelper;
  final EncryptionService encryptionService;

  const E2eeChatCryptoService({
    required this.secureStorage,
    required this.deviceInfoHelper,
    required this.encryptionService,
  });

  Future<void> ensureOwnDeviceRegistered(Dio dio) async {
    final keyPair = await _ensureLocalIdentityKeyPair();
    final publicKey = encryptionService.encodePublicKey(keyPair.publicKey);
    final deviceInfo = await deviceInfoHelper.getDeviceInfo();
    final signature =
        base64.encode(sha256.convert(utf8.encode(publicKey)).bytes);

    await dio.post(
      ApiConstants.e2eeDevices,
      data: {
        'device_id': deviceInfo.deviceId,
        'device_label': deviceInfo.deviceName,
        'bundle_version': _bundleVersion,
        'identity_key_algorithm': 'P-256',
        'identity_key_public': publicKey,
        'signed_pre_key_id': _keyId,
        'signed_pre_key_public': publicKey,
        'signed_pre_key_signature': signature,
        'one_time_pre_keys': const [],
      },
    );
  }

  Future<EncryptedChatPayload> encryptForConsultation({
    required Dio dio,
    required String consultationId,
    required String currentUserId,
    required String plaintext,
  }) async {
    await ensureOwnDeviceRegistered(dio);

    final peerUserId = await _resolvePeerUserId(
      dio: dio,
      consultationId: consultationId,
      currentUserId: currentUserId,
    );
    final peerPublicKey = await _fetchPeerIdentityPublicKey(
      dio: dio,
      peerUserId: peerUserId,
      consultationId: consultationId,
    );
    final privateKey = await _readLocalPrivateKey();
    final sharedKey = encryptionService.deriveAes256Key(
      privateKey,
      encryptionService.decodePublicKey(peerPublicKey),
    );
    final encrypted = encryptionService.encryptDetached(plaintext, sharedKey);

    return EncryptedChatPayload(
      ciphertext: encrypted.ciphertext,
      nonce: encrypted.nonce,
      algorithm: algorithm,
      keyId: _keyId,
    );
  }

  Future<String> decryptForConsultation({
    required Dio dio,
    required String consultationId,
    required String currentUserId,
    required String senderUserId,
    required String? recipientUserId,
    required String ciphertext,
    required String? nonce,
  }) async {
    if (ciphertext.isEmpty || nonce == null || nonce.isEmpty) {
      return _encryptedUnavailableLabel;
    }

    try {
      await ensureOwnDeviceRegistered(dio);

      final peerUserId = senderUserId == currentUserId
          ? recipientUserId ??
              await _resolvePeerUserId(
                dio: dio,
                consultationId: consultationId,
                currentUserId: currentUserId,
              )
          : senderUserId;

      final peerPublicKey = await _fetchPeerIdentityPublicKey(
        dio: dio,
        peerUserId: peerUserId,
        consultationId: consultationId,
      );
      final privateKey = await _readLocalPrivateKey();
      final sharedKey = encryptionService.deriveAes256Key(
        privateKey,
        encryptionService.decodePublicKey(peerPublicKey),
      );

      return encryptionService.decryptDetached(
        ciphertextBase64: ciphertext,
        nonceBase64: nonce,
        key: sharedKey,
      );
    } catch (_) {
      return _encryptedUnavailableLabel;
    }
  }

  Future<({PublicKey publicKey, PrivateKey privateKey})>
      _ensureLocalIdentityKeyPair() async {
    final privateKey = await secureStorage.read(
      key: AppConstants.keyE2ePrivateKey,
    );
    final publicKey = await secureStorage.read(
      key: AppConstants.keyE2ePublicKey,
    );

    if (privateKey != null &&
        privateKey.isNotEmpty &&
        publicKey != null &&
        publicKey.isNotEmpty) {
      return (
        privateKey: encryptionService.decodePrivateKey(privateKey),
        publicKey: encryptionService.decodePublicKey(publicKey),
      );
    }

    final keyPair = encryptionService.generateKeyPair();
    await secureStorage.write(
      key: AppConstants.keyE2ePrivateKey,
      value: encryptionService.encodePrivateKey(keyPair.privateKey),
    );
    await secureStorage.write(
      key: AppConstants.keyE2ePublicKey,
      value: encryptionService.encodePublicKey(keyPair.publicKey),
    );

    return (
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
    );
  }

  Future<PrivateKey> _readLocalPrivateKey() async {
    await _ensureLocalIdentityKeyPair();
    final privateKey = await secureStorage.read(
      key: AppConstants.keyE2ePrivateKey,
    );

    if (privateKey == null || privateKey.isEmpty) {
      throw const E2eeUnavailableException(
        'Clé privée E2EE locale indisponible',
      );
    }

    return encryptionService.decodePrivateKey(privateKey);
  }

  Future<String> _resolvePeerUserId({
    required Dio dio,
    required String consultationId,
    required String currentUserId,
  }) async {
    final response = await dio.get(
      ApiConstants.appointmentShow.replaceFirst('{id}', consultationId),
    );
    final data = extractDataMap(response.data);
    final appointment = data['appointment'] is Map<String, dynamic>
        ? data['appointment'] as Map<String, dynamic>
        : data;
    final patientUserId = appointment['patient_user_id']?.toString();
    final doctorUserId = appointment['doctor_user_id']?.toString();

    if (patientUserId == null || doctorUserId == null) {
      throw const E2eeUnavailableException(
        'Participants de consultation introuvables',
      );
    }

    if (currentUserId == patientUserId) {
      return doctorUserId;
    }
    if (currentUserId == doctorUserId) {
      return patientUserId;
    }

    throw const E2eeUnavailableException(
      'Utilisateur non autorisé pour cette consultation',
    );
  }

  Future<String> _fetchPeerIdentityPublicKey({
    required Dio dio,
    required String peerUserId,
    required String consultationId,
  }) async {
    final response = await dio.get(
      ApiConstants.e2eePeerBundle.replaceFirst('{userId}', peerUserId),
      queryParameters: {'consultation_id': consultationId},
    );
    final bundle = extractDataMap(response.data);
    final devices = bundle['devices'];

    if (devices is! List || devices.isEmpty) {
      throw const E2eeUnavailableException(
        'Le destinataire doit ouvrir l’application pour publier sa clé E2EE.',
      );
    }

    final firstDevice = devices.first;
    if (firstDevice is! Map<String, dynamic>) {
      throw const E2eeUnavailableException('Bundle E2EE invalide.');
    }

    final publicKey = firstDevice['identity_key_public']?.toString();
    if (publicKey == null || publicKey.isEmpty) {
      throw const E2eeUnavailableException('Clé publique E2EE indisponible.');
    }

    return publicKey;
  }
}

final e2eeChatCryptoServiceProvider = Provider<E2eeChatCryptoService>((ref) {
  return E2eeChatCryptoService(
    secureStorage: ref.watch(secureStorageProvider),
    deviceInfoHelper: ref.watch(deviceInfoHelperProvider),
    encryptionService: EncryptionService(),
  );
});
